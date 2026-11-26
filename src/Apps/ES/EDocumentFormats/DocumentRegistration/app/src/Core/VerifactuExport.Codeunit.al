// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Verifactu;

using Microsoft.EServices.EDocument;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Clause;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Sales.History;
using Microsoft.Service.History;
using System.DateTime;
using System.Security.Encryption;
using System.Telemetry;
using System.Text;
using System.Utilities;

codeunit 10778 "Verifactu Export"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "E-Document" = rimd,
                  tabledata "E-Document Log" = rimd,
                  tabledata "E-Doc. Data Storage" = rimd,
                  tabledata "Sales Invoice Header" = rm,
                  tabledata "Sales Invoice Line" = rm,
                  tabledata "Sales Cr.Memo Header" = rm,
                  tabledata "Sales Cr.Memo Line" = rm,
                  tabledata "Service Invoice Header" = rm,
                  tabledata "Service Invoice Line" = rm,
                  tabledata "No Taxable Entry" = r;

    var
        CompanyInformation: Record "Company Information";
        VerifactuSetup: Record "Verifactu Setup";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        VerifactuDocUploadMgt: Codeunit "Verifactu Doc. Upload Mgt.";
        XmlNamespaceSoapenv, XmlNamespaceSum, XmlNamespaceSum1 : Text;
        FeatureNameTok: Label 'EDocument Format Verifactu', Locked = true;
        StartEventNameTok: Label 'Export initiated. IsBatch is: %1', Locked = true;
        EndEventNameTok: Label 'Export completed', Locked = true;
        MaxBatchSizeErr: Label 'Sending more than 1000 documents in a batch is not allowed.';

    procedure Export(var SourceDocumentHeader: RecordRef; var SourceDocumentLines: RecordRef; var EDocument: Record "E-Document"; var TempBlob: Codeunit "Temp Blob"; IsBatch: Boolean)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        ServiceInvoiceLine: Record "Service Invoice Line";
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
    begin
        OnBeforeExport(SourceDocumentHeader, SourceDocumentLines, TempBlob, IsBatch);
        FeatureTelemetry.LogUsage('0000OCR', FeatureNameTok, StrSubstNo(StartEventNameTok, Format(IsBatch)));
        CompanyInformation.Get();
        if not VerifactuSetup.Get() then
            VerifactuSetup.Init();

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
        end;
        FeatureTelemetry.LogUsage('0000OCT', FeatureNameTok, EndEventNameTok);
        OnAfterExport(SourceDocumentHeader, SourceDocumentLines, TempBlob, IsBatch);
    end;

    #region Invoice
    local procedure ExportInvoice(var EDocument: Record "E-Document"; var SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesInvoiceLine: Record "Sales Invoice Line"; var TempBlob: Codeunit "Temp Blob"; IsBatch: Boolean)
    var
        HeaderXMLNode, BodyXMLNode, RegFactuSistemaFacturacionXMLNode, RootXMLNode : XmlElement;
        XMLDocOut: XmlDocument;
        FileOutStream: OutStream;
    begin
        TempBlob.CreateOutStream(FileOutStream, TextEncoding::UTF8);

        XmlDocument.ReadFrom(GetBasicXMLHeader(), XMLDocOut);
        XMLDocOut.GetRoot(RootXMLNode);

        InitializeNamespaces();
        HeaderXMLNode := XmlElement.Create('Header', XmlNamespaceSoapenv);
        BodyXMLNode := XmlElement.Create('Body', XmlNamespaceSoapenv);
        RegFactuSistemaFacturacionXMLNode := XmlElement.Create('RegFactuSistemaFacturacion', XmlNamespaceSum);
        InsertHeaderData(RegFactuSistemaFacturacionXMLNode);
        InsertInvoicesData(RegFactuSistemaFacturacionXMLNode, SalesInvoiceHeader, SalesInvoiceLine, IsBatch, EDocument);

        BodyXMLNode.Add(RegFactuSistemaFacturacionXMLNode);
        RootXMLNode.Add(HeaderXMLNode);
        RootXMLNode.Add(BodyXMLNode);

        XmlDocOut.WriteTo(FileOutStream);
    end;

    local procedure InsertInvoicesData(var RootXMLNode: XmlElement; var SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesInvoiceLine: Record "Sales Invoice Line"; IsBatch: Boolean; var EDocument: Record "E-Document")
    var
        InvoiceXMLNode: XmlElement;
        InvoiceCount: Integer;
    begin
        InvoiceXMLNode := XmlElement.Create('RegistroFactura', XmlNamespaceSum);

        if IsBatch then begin
            SalesInvoiceHeader.SetAutoCalcFields(Amount, "Amount Including VAT");
            SalesInvoiceHeader.FindSet();
            repeat
                InvoiceCount += 1;
                if InvoiceCount > 1000 then
                    Error(MaxBatchSizeErr);
                InsertInvoice(InvoiceXMLNode, SalesInvoiceHeader, SalesInvoiceLine, EDocument);
            until SalesInvoiceHeader.Next() = 0;
        end else begin
            SalesInvoiceHeader.CalcFields(Amount, "Amount Including VAT");
            InsertInvoice(InvoiceXMLNode, SalesInvoiceHeader, SalesInvoiceLine, EDocument);
        end;
        RootXMLNode.Add(InvoiceXMLNode);
    end;

    local procedure InsertInvoice(var RootXMLNode: XmlElement; var SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesInvoiceLine: Record "Sales Invoice Line"; var EDocument: Record "E-Document")
    var
        TempBlobQR: Codeunit "Temp Blob";
        InvoiceType, VerifactuDateTime : Text;
        PreviousDocumentNo, PreviousHuella : Text;
        VerifactuHash: Text[64];
        PreviousPostingDate: Date;
        InvoiceXMLNode: XmlElement;
        OutStr: OutStream;
        InStr: InStream;
    begin
        InvoiceType := GetOptionFirstTwoChars(SalesInvoiceHeader."Invoice Type");
        VerifactuDateTime := GetCustomDateTimeFormat(CurrentDateTime());
        FindLastRegisteredDocument(PreviousDocumentNo, PreviousPostingDate, PreviousHuella);
        VerifactuHash := GenerateHash(SalesInvoiceHeader, InvoiceType, VerifactuDateTime, PreviousHuella);
        VerifactuDocUploadMgt.InsertVerifactuDocument(EDocument, SalesInvoiceHeader."No.", SalesInvoiceHeader."Posting Date", VerifactuHash);

        InvoiceXMLNode := XmlElement.Create('RegistroAlta', XmlNamespaceSum1);

        InsertInvoiceHeaderData(InvoiceXMLNode, SalesInvoiceHeader, InvoiceType);
        InsertInvoiceBreakdown(InvoiceXMLNode, SalesInvoiceHeader, SalesInvoiceLine);
        InsertTotals(InvoiceXMLNode, SalesInvoiceHeader);
        InsertRegistroAnterior(InvoiceXMLNode, PreviousDocumentNo, PreviousPostingDate, PreviousHuella);
        InsertInformationSystem(InvoiceXMLNode);
        InsertHuellaDigital(InvoiceXMLNode, VerifactuDateTime, VerifactuHash);

        RootXMLNode.Add(InvoiceXMLNode);

        TempBlobQR := GenerateQRCode(SalesInvoiceHeader."No.", SalesInvoiceHeader."Posting Date", SalesInvoiceHeader."Amount Including VAT");
        TempBlobQR.CreateInStream(InStr);
        SalesInvoiceHeader."QR Code Base64".CreateOutStream(OutStr, TextEncoding::UTF8);
        CopyStream(OutStr, InStr);
        SalesInvoiceHeader."QR Code Image".ImportStream(InStr, 'image.png');
        SalesInvoiceHeader.Modify();
    end;

    local procedure InsertInvoiceHeaderData(var InvoiceXMLNode: XmlElement; var SalesInvoiceHeader: Record "Sales Invoice Header"; InvoiceType: Text)
    var
        IDFacturaXMLNode: XmlElement;
    begin
        InvoiceXMLNode.Add(XmlElement.Create('IDVersion', XmlNamespaceSum1, '1.0'));

        IDFacturaXMLNode := XmlElement.Create('IDFactura', XmlNamespaceSum1);
        IDFacturaXMLNode.Add(XmlElement.Create('IDEmisorFactura', XmlNamespaceSum1, CompanyInformation."VAT Registration No."));
        IDFacturaXMLNode.Add(XmlElement.Create('NumSerieFactura', XmlNamespaceSum1, SalesInvoiceHeader."No."));
        IDFacturaXMLNode.Add(XmlElement.Create('FechaExpedicionFactura', XmlNamespaceSum1, FormatDate(SalesInvoiceHeader."Posting Date")));
        InvoiceXMLNode.Add(IDFacturaXMLNode);

        InvoiceXMLNode.Add(XmlElement.Create('NombreRazonEmisor', XmlNamespaceSum1, CompanyInformation."Name"));
        InvoiceXMLNode.Add(XmlElement.Create('TipoFactura', XmlNamespaceSum1, InvoiceType));
        if SalesInvoiceHeader."Operation Description" = '' then
            SalesInvoiceHeader."Operation Description" := SalesInvoiceHeader."No.";
        InvoiceXMLNode.Add(XmlElement.Create('DescripcionOperacion', XmlNamespaceSum1, SalesInvoiceHeader."Operation Description"));

        InsertRecipient(
            InvoiceXMLNode, SalesInvoiceHeader."Bill-to Name", SalesInvoiceHeader."VAT Registration No.",
            GetRecipientCountryRegionCode(SalesInvoiceHeader."Alt. VAT Registration No.", SalesInvoiceHeader."VAT Country/Region Code", SalesInvoiceHeader."Bill-to Country/Region Code", SalesInvoiceHeader."Sell-to Country/Region Code"),
            SalesInvoiceHeader."ID Type");
    end;

    local procedure InsertInvoiceBreakdown(var InvoiceXMLNode: XmlElement; var SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesInvoiceLine: Record "Sales Invoice Line")
    var
        TempSalesInvoiceLine: Record "Sales Invoice Line" temporary;
        DesgloseXMLNode: XmlElement;
        IsIntraCommunity: Boolean;
    begin
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.SetFilter(Type, '<>%1', SalesInvoiceLine.Type::" ");
        if SalesInvoiceLine.FindSet() then
            repeat
                if FindLineInTempSalesInvoiceLine(TempSalesInvoiceLine, SalesInvoiceLine) then begin
                    TempSalesInvoiceLine.Amount += SalesInvoiceLine.Amount;
                    TempSalesInvoiceLine."Amount Including VAT" += SalesInvoiceLine."Amount Including VAT";
                    TempSalesInvoiceLine.Modify();
                end else begin
                    TempSalesInvoiceLine.Init();
                    TempSalesInvoiceLine := SalesInvoiceLine;
                    TempSalesInvoiceLine.Insert();
                end;
            until SalesInvoiceLine.Next() = 0;

        DesgloseXMLNode := XmlElement.Create('Desglose', XmlNamespaceSum1);
        IsIntraCommunity := IsIntraCommunityRecipient(GetRecipientCountryRegionCode(SalesInvoiceHeader."Alt. VAT Registration No.", SalesInvoiceHeader."VAT Country/Region Code", SalesInvoiceHeader."Bill-to Country/Region Code", SalesInvoiceHeader."Sell-to Country/Region Code"));

        TempSalesInvoiceLine.Reset();
        TempSalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        if TempSalesInvoiceLine.FindSet() then
            repeat
                InsertBreakdownDetail(
                    DesgloseXMLNode, SalesInvoiceHeader."No.", SalesInvoiceHeader."Posting Date",
                    GetOptionFirstTwoChars(SalesInvoiceHeader."Special Scheme Code"), TempSalesInvoiceLine."VAT Bus. Posting Group",
                    TempSalesInvoiceLine."VAT Prod. Posting Group", TempSalesInvoiceLine."VAT Identifier", TempSalesInvoiceLine."VAT %",
                    TempSalesInvoiceLine.Amount, TempSalesInvoiceLine."Amount Including VAT" - TempSalesInvoiceLine.Amount,
                    false, IsIntraCommunity);
            until TempSalesInvoiceLine.Next() = 0;
        TempSalesInvoiceLine.CalcSums(Amount, "Amount Including VAT");

        InvoiceXMLNode.Add(DesgloseXMLNode);
    end;

    local procedure InsertTotals(var InvoiceXMLNode: XmlElement; var SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        InvoiceXMLNode.Add(XmlElement.Create('CuotaTotal', XmlNamespaceSum1, FormatAmount(SalesInvoiceHeader."Amount Including VAT" - SalesInvoiceHeader.Amount)));
        InvoiceXMLNode.Add(XmlElement.Create('ImporteTotal', XmlNamespaceSum1, FormatAmount(SalesInvoiceHeader."Amount Including VAT")));
    end;

    local procedure FindLineInTempSalesInvoiceLine(var TempSalesInvoiceLine: Record "Sales Invoice Line" temporary; var SalesInvoiceLine: Record "Sales Invoice Line"): Boolean
    begin
        TempSalesInvoiceLine.SetRange("Document No.", SalesInvoiceLine."Document No.");
        TempSalesInvoiceLine.SetRange("VAT %", SalesInvoiceLine."VAT %");
        TempSalesInvoiceLine.SetRange("VAT Bus. Posting Group", SalesInvoiceLine."VAT Bus. Posting Group");
        TempSalesInvoiceLine.SetRange("VAT Prod. Posting Group", SalesInvoiceLine."VAT Prod. Posting Group");
        TempSalesInvoiceLine.SetRange("VAT Identifier", SalesInvoiceLine."VAT Identifier");
        exit(TempSalesInvoiceLine.FindFirst());
    end;

    local procedure GenerateHash(SalesInvoiceHeader: Record "Sales Invoice Header"; InvoiceType: Text; VerifactuDateTime: Text; PreviousHuella: Text): Text[64]
    var
        CryptographyManagement: Codeunit "Cryptography Management";
        HashAlgorithmType: Option MD5,SHA1,SHA256,SHA384,SHA512;
        InputString: Text;
    begin
        InputString :=
            'IDEmisorFactura=' + CompanyInformation."VAT Registration No." +
            '&' +
            'NumSerieFactura=' + SalesInvoiceHeader."No." +
            '&' +
            'FechaExpedicionFactura=' + Format(SalesInvoiceHeader."Posting Date", 0, '<Day,2>-<Month,2>-<Year4>') +
            '&' +
            'TipoFactura=' + InvoiceType +
            '&' +
            'CuotaTotal=' + FormatAmount(SalesInvoiceHeader."Amount Including VAT" - SalesInvoiceHeader.Amount) +
            '&' +
            'ImporteTotal=' + FormatAmount(SalesInvoiceHeader."Amount Including VAT") +
            '&' +
            'Huella=' + PreviousHuella +
            '&' +
            'FechaHoraHusoGenRegistro=' + VerifactuDateTime;
        exit(
            CopyStr(
                CryptographyManagement.GenerateHash(InputString, HashAlgorithmType::SHA256), 1, 64));
    end;
    #endregion
    #region Service Invoice
    local procedure ExportServiceInvoice(var EDocument: Record "E-Document"; var ServiceInvoiceHeader: Record "Service Invoice Header"; var ServiceInvoiceLine: Record "Service Invoice Line"; var TempBlob: Codeunit "Temp Blob"; IsBatch: Boolean)
    var
        HeaderXMLNode, BodyXMLNode, RegFactuSistemaFacturacionXMLNode, RootXMLNode : XmlElement;
        XMLDocOut: XmlDocument;
        FileOutStream: OutStream;
    begin
        TempBlob.CreateOutStream(FileOutStream, TextEncoding::UTF8);

        XmlDocument.ReadFrom(GetBasicXMLHeader(), XMLDocOut);
        XMLDocOut.GetRoot(RootXMLNode);

        InitializeNamespaces();
        HeaderXMLNode := XmlElement.Create('Header', XmlNamespaceSoapenv);
        BodyXMLNode := XmlElement.Create('Body', XmlNamespaceSoapenv);
        RegFactuSistemaFacturacionXMLNode := XmlElement.Create('RegFactuSistemaFacturacion', XmlNamespaceSum);
        InsertHeaderData(RegFactuSistemaFacturacionXMLNode);
        InsertServiceInvoicesData(RegFactuSistemaFacturacionXMLNode, ServiceInvoiceHeader, ServiceInvoiceLine, IsBatch, EDocument);

        BodyXMLNode.Add(RegFactuSistemaFacturacionXMLNode);
        RootXMLNode.Add(HeaderXMLNode);
        RootXMLNode.Add(BodyXMLNode);

        XmlDocOut.WriteTo(FileOutStream);
    end;

    local procedure InsertServiceInvoicesData(var RootXMLNode: XmlElement; var ServiceInvoiceHeader: Record "Service Invoice Header"; var ServiceInvoiceLine: Record "Service Invoice Line"; IsBatch: Boolean; var EDocument: Record "E-Document")
    var
        InvoiceXMLNode: XmlElement;
        InvoiceCount: Integer;
    begin
        InvoiceXMLNode := XmlElement.Create('RegistroFactura', XmlNamespaceSum);

        if IsBatch then begin
            ServiceInvoiceHeader.SetAutoCalcFields(Amount, "Amount Including VAT");
            ServiceInvoiceHeader.FindSet();
            repeat
                InvoiceCount += 1;
                if InvoiceCount > 1000 then
                    Error(MaxBatchSizeErr);
                InsertServiceInvoice(InvoiceXMLNode, ServiceInvoiceHeader, ServiceInvoiceLine, EDocument);
            until ServiceInvoiceHeader.Next() = 0;
        end else begin
            ServiceInvoiceHeader.CalcFields(Amount, "Amount Including VAT");
            InsertServiceInvoice(InvoiceXMLNode, ServiceInvoiceHeader, ServiceInvoiceLine, EDocument);
        end;
        RootXMLNode.Add(InvoiceXMLNode);
    end;

    local procedure InsertServiceInvoice(var RootXMLNode: XmlElement; var ServiceInvoiceHeader: Record "Service Invoice Header"; var ServiceInvoiceLine: Record "Service Invoice Line"; var EDocument: Record "E-Document")
    var
        TempBlobQR: Codeunit "Temp Blob";
        InvoiceType, VerifactuDateTime : Text;
        PreviousDocumentNo, PreviousHuella : Text;
        VerifactuHash: Text[64];
        PreviousPostingDate: Date;
        InvoiceXMLNode: XmlElement;
        OutStr: OutStream;
        InStr: InStream;
    begin
        InvoiceType := GetOptionFirstTwoChars(ServiceInvoiceHeader."Invoice Type");
        VerifactuDateTime := GetCustomDateTimeFormat(CurrentDateTime());
        FindLastRegisteredDocument(PreviousDocumentNo, PreviousPostingDate, PreviousHuella);
        VerifactuHash := GenerateHash(ServiceInvoiceHeader, InvoiceType, VerifactuDateTime, PreviousHuella);
        VerifactuDocUploadMgt.InsertVerifactuDocument(EDocument, ServiceInvoiceHeader."No.", ServiceInvoiceHeader."Posting Date", VerifactuHash);

        InvoiceXMLNode := XmlElement.Create('RegistroAlta', XmlNamespaceSum1);

        InsertServiceInvoiceHeaderData(InvoiceXMLNode, ServiceInvoiceHeader, InvoiceType);
        InsertServiceInvoiceBreakdown(InvoiceXMLNode, ServiceInvoiceHeader, ServiceInvoiceLine);
        InsertTotals(InvoiceXMLNode, ServiceInvoiceHeader);
        InsertRegistroAnterior(InvoiceXMLNode, PreviousDocumentNo, PreviousPostingDate, PreviousHuella);
        InsertInformationSystem(InvoiceXMLNode);
        InsertHuellaDigital(InvoiceXMLNode, VerifactuDateTime, VerifactuHash);

        RootXMLNode.Add(InvoiceXMLNode);

        TempBlobQR := GenerateQRCode(ServiceInvoiceHeader."No.", ServiceInvoiceHeader."Posting Date", ServiceInvoiceHeader."Amount Including VAT");
        TempBlobQR.CreateInStream(InStr);
        ServiceInvoiceHeader."QR Code Base64".CreateOutStream(OutStr, TextEncoding::UTF8);
        CopyStream(OutStr, InStr);
        ServiceInvoiceHeader."QR Code Image".ImportStream(InStr, 'image.png');
        ServiceInvoiceHeader.Modify();
    end;

    local procedure InsertServiceInvoiceHeaderData(var InvoiceXMLNode: XmlElement; var ServiceInvoiceHeader: Record "Service Invoice Header"; InvoiceType: Text)
    var
        IDFacturaXMLNode: XmlElement;
    begin
        InvoiceXMLNode.Add(XmlElement.Create('IDVersion', XmlNamespaceSum1, '1.0'));

        IDFacturaXMLNode := XmlElement.Create('IDFactura', XmlNamespaceSum1);
        IDFacturaXMLNode.Add(XmlElement.Create('IDEmisorFactura', XmlNamespaceSum1, CompanyInformation."VAT Registration No."));
        IDFacturaXMLNode.Add(XmlElement.Create('NumSerieFactura', XmlNamespaceSum1, ServiceInvoiceHeader."No."));
        IDFacturaXMLNode.Add(XmlElement.Create('FechaExpedicionFactura', XmlNamespaceSum1, FormatDate(ServiceInvoiceHeader."Posting Date")));
        InvoiceXMLNode.Add(IDFacturaXMLNode);

        InvoiceXMLNode.Add(XmlElement.Create('NombreRazonEmisor', XmlNamespaceSum1, CompanyInformation."Name"));
        InvoiceXMLNode.Add(XmlElement.Create('TipoFactura', XmlNamespaceSum1, InvoiceType));
        if ServiceInvoiceHeader."Operation Description" = '' then
            ServiceInvoiceHeader."Operation Description" := ServiceInvoiceHeader."No.";
        InvoiceXMLNode.Add(XmlElement.Create('DescripcionOperacion', XmlNamespaceSum1, ServiceInvoiceHeader."Operation Description"));

        InsertRecipient(
            InvoiceXMLNode, ServiceInvoiceHeader."Bill-to Name", ServiceInvoiceHeader."VAT Registration No.",
            GetRecipientCountryRegionCode(false, ServiceInvoiceHeader."VAT Country/Region Code", ServiceInvoiceHeader."Bill-to Country/Region Code", ServiceInvoiceHeader."Country/Region Code"),
            ServiceInvoiceHeader."ID Type");
    end;

    local procedure InsertServiceInvoiceBreakdown(var InvoiceXMLNode: XmlElement; var ServiceInvoiceHeader: Record "Service Invoice Header"; var ServiceInvoiceLine: Record "Service Invoice Line")
    var
        TempServiceInvoiceLine: Record "Service Invoice Line" temporary;
        DesgloseXMLNode: XmlElement;
        IsIntraCommunity: Boolean;
    begin
        ServiceInvoiceLine.SetRange("Document No.", ServiceInvoiceHeader."No.");
        ServiceInvoiceLine.SetFilter(Type, '<>%1', ServiceInvoiceLine.Type::" ");
        if ServiceInvoiceLine.FindSet() then
            repeat
                if FindLineInTempServiceInvoiceLine(TempServiceInvoiceLine, ServiceInvoiceLine) then begin
                    TempServiceInvoiceLine.Amount += ServiceInvoiceLine.Amount;
                    TempServiceInvoiceLine."Amount Including VAT" += ServiceInvoiceLine."Amount Including VAT";
                    TempServiceInvoiceLine.Modify();
                end else begin
                    TempServiceInvoiceLine.Init();
                    TempServiceInvoiceLine := ServiceInvoiceLine;
                    TempServiceInvoiceLine.Insert();
                end;
            until ServiceInvoiceLine.Next() = 0;

        DesgloseXMLNode := XmlElement.Create('Desglose', XmlNamespaceSum1);
        IsIntraCommunity := IsIntraCommunityRecipient(GetRecipientCountryRegionCode(false, ServiceInvoiceHeader."VAT Country/Region Code", ServiceInvoiceHeader."Bill-to Country/Region Code", ServiceInvoiceHeader."Country/Region Code"));

        TempServiceInvoiceLine.Reset();
        TempServiceInvoiceLine.SetRange("Document No.", ServiceInvoiceHeader."No.");
        if TempServiceInvoiceLine.FindSet() then
            repeat
                InsertBreakdownDetail(
                    DesgloseXMLNode, ServiceInvoiceHeader."No.", ServiceInvoiceHeader."Posting Date",
                    GetOptionFirstTwoChars(ServiceInvoiceHeader."Special Scheme Code"), TempServiceInvoiceLine."VAT Bus. Posting Group",
                    TempServiceInvoiceLine."VAT Prod. Posting Group", TempServiceInvoiceLine."VAT Identifier", TempServiceInvoiceLine."VAT %",
                    TempServiceInvoiceLine.Amount, TempServiceInvoiceLine."Amount Including VAT" - TempServiceInvoiceLine.Amount,
                    false, IsIntraCommunity);
            until TempServiceInvoiceLine.Next() = 0;
        TempServiceInvoiceLine.CalcSums(Amount, "Amount Including VAT");

        InvoiceXMLNode.Add(DesgloseXMLNode);
    end;

    local procedure InsertTotals(var InvoiceXMLNode: XmlElement; var ServiceInvoiceHeader: Record "Service Invoice Header")
    begin
        InvoiceXMLNode.Add(XmlElement.Create('CuotaTotal', XmlNamespaceSum1, FormatAmount(ServiceInvoiceHeader."Amount Including VAT" - ServiceInvoiceHeader.Amount)));
        InvoiceXMLNode.Add(XmlElement.Create('ImporteTotal', XmlNamespaceSum1, FormatAmount(ServiceInvoiceHeader."Amount Including VAT")));
    end;

    local procedure FindLineInTempServiceInvoiceLine(var TempServiceInvoiceLine: Record "Service Invoice Line" temporary; var ServiceInvoiceLine: Record "Service Invoice Line"): Boolean
    begin
        TempServiceInvoiceLine.SetRange("Document No.", ServiceInvoiceLine."Document No.");
        TempServiceInvoiceLine.SetRange("VAT %", ServiceInvoiceLine."VAT %");
        TempServiceInvoiceLine.SetRange("VAT Bus. Posting Group", ServiceInvoiceLine."VAT Bus. Posting Group");
        TempServiceInvoiceLine.SetRange("VAT Prod. Posting Group", ServiceInvoiceLine."VAT Prod. Posting Group");
        TempServiceInvoiceLine.SetRange("VAT Identifier", ServiceInvoiceLine."VAT Identifier");
        exit(TempServiceInvoiceLine.FindFirst());
    end;

    local procedure GenerateHash(ServiceInvoiceHeader: Record "Service Invoice Header"; InvoiceType: Text; VerifactuDateTime: Text; PreviousHuella: Text): Text[64]
    var
        CryptographyManagement: Codeunit "Cryptography Management";
        HashAlgorithmType: Option MD5,SHA1,SHA256,SHA384,SHA512;
        InputString: Text;
    begin
        InputString :=
            'IDEmisorFactura=' + CompanyInformation."VAT Registration No." +
            '&' +
            'NumSerieFactura=' + ServiceInvoiceHeader."No." +
            '&' +
            'FechaExpedicionFactura=' + Format(ServiceInvoiceHeader."Posting Date", 0, '<Day,2>-<Month,2>-<Year4>') +
            '&' +
            'TipoFactura=' + InvoiceType +
            '&' +
            'CuotaTotal=' + FormatAmount(ServiceInvoiceHeader."Amount Including VAT" - ServiceInvoiceHeader.Amount) +
            '&' +
            'ImporteTotal=' + FormatAmount(ServiceInvoiceHeader."Amount Including VAT") +
            '&' +
            'Huella=' + PreviousHuella +
            '&' +
            'FechaHoraHusoGenRegistro=' + VerifactuDateTime;
        exit(
            CopyStr(
                CryptographyManagement.GenerateHash(InputString, HashAlgorithmType::SHA256), 1, 64));
    end;
    #endregion
    #region Credit Memo
    local procedure ExportCreditMemo(var EDocument: Record "E-Document"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var SalesCrMemoLine: Record "Sales Cr.Memo Line"; var TempBlob: Codeunit "Temp Blob"; IsBatch: Boolean)
    var
        HeaderXMLNode, BodyXMLNode, RegFactuSistemaFacturacionXMLNode, RootXMLNode : XmlElement;
        XMLDocOut: XmlDocument;
        FileOutStream: OutStream;
    begin
        TempBlob.CreateOutStream(FileOutStream, TextEncoding::UTF8);

        XmlDocument.ReadFrom(GetBasicXMLHeader(), XMLDocOut);
        XMLDocOut.GetRoot(RootXMLNode);

        InitializeNamespaces();
        HeaderXMLNode := XmlElement.Create('Header', XmlNamespaceSoapenv);
        BodyXMLNode := XmlElement.Create('Body', XmlNamespaceSoapenv);
        RegFactuSistemaFacturacionXMLNode := XmlElement.Create('RegFactuSistemaFacturacion', XmlNamespaceSum);
        InsertHeaderData(RegFactuSistemaFacturacionXMLNode);
        InsertCreditMemosData(RegFactuSistemaFacturacionXMLNode, SalesCrMemoHeader, SalesCrMemoLine, IsBatch, EDocument);

        BodyXMLNode.Add(RegFactuSistemaFacturacionXMLNode);
        RootXMLNode.Add(HeaderXMLNode);
        RootXMLNode.Add(BodyXMLNode);

        XmlDocOut.WriteTo(FileOutStream);
    end;

    local procedure InsertCreditMemosData(var RootXMLNode: XmlElement; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var SalesCrMemoLine: Record "Sales Cr.Memo Line"; IsBatch: Boolean; var EDocument: Record "E-Document")
    var
        CreditMemoXMLNode: XmlElement;
        CreditMemoCount: Integer;
    begin
        CreditMemoXMLNode := XmlElement.Create('RegistroFactura', XmlNamespaceSum);

        if IsBatch then begin
            SalesCrMemoHeader.SetAutoCalcFields(Amount, "Amount Including VAT");
            SalesCrMemoHeader.FindSet();
            repeat
                CreditMemoCount += 1;
                if CreditMemoCount > 1000 then
                    Error(MaxBatchSizeErr);
                InsertCreditMemo(CreditMemoXMLNode, SalesCrMemoHeader, SalesCrMemoLine, EDocument);
            until SalesCrMemoHeader.Next() = 0;
        end else begin
            SalesCrMemoHeader.CalcFields(Amount, "Amount Including VAT");
            InsertCreditMemo(CreditMemoXMLNode, SalesCrMemoHeader, SalesCrMemoLine, EDocument);
        end;
        RootXMLNode.Add(CreditMemoXMLNode);
    end;

    local procedure InsertCreditMemo(var RootXMLNode: XmlElement; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var SalesCrMemoLine: Record "Sales Cr.Memo Line"; var EDocument: Record "E-Document")
    var
        TempBlobQR: Codeunit "Temp Blob";
        InvoiceType, VerifactuDateTime : Text;
        PreviousDocumentNo, PreviousHuella : Text;
        VerifactuHash: Text[64];
        PreviousPostingDate: Date;
        CrMemoXMLNode: XmlElement;
        OutStr: OutStream;
        InStr: InStream;
    begin
        InvoiceType := GetOptionFirstTwoChars(SalesCrMemoHeader."Cr. Memo Type");
        VerifactuDateTime := GetCustomDateTimeFormat(CurrentDateTime());
        FindLastRegisteredDocument(PreviousDocumentNo, PreviousPostingDate, PreviousHuella);
        VerifactuHash := GenerateHash(SalesCrMemoHeader, InvoiceType, VerifactuDateTime, PreviousHuella);
        VerifactuDocUploadMgt.InsertVerifactuDocument(EDocument, SalesCrMemoHeader."No.", SalesCrMemoHeader."Posting Date", VerifactuHash);

        CrMemoXMLNode := XmlElement.Create('RegistroAlta', XmlNamespaceSum1);

        InsertCreditMemoHeaderData(CrMemoXMLNode, SalesCrMemoHeader, InvoiceType);
        InsertCreditMemoBreakdown(CrMemoXMLNode, SalesCrMemoHeader, SalesCrMemoLine);
        InsertTotals(CrMemoXMLNode, SalesCrMemoHeader);
        InsertRegistroAnterior(CrMemoXMLNode, PreviousDocumentNo, PreviousPostingDate, PreviousHuella);
        InsertInformationSystem(CrMemoXMLNode);
        InsertHuellaDigital(CrMemoXMLNode, VerifactuDateTime, VerifactuHash);

        RootXMLNode.Add(CrMemoXMLNode);

        TempBlobQR := GenerateQRCode(SalesCrMemoHeader."No.", SalesCrMemoHeader."Posting Date", SalesCrMemoHeader."Amount Including VAT");
        TempBlobQR.CreateInStream(InStr);
        SalesCrMemoHeader."QR Code Base64".CreateOutStream(OutStr, TextEncoding::UTF8);
        CopyStream(OutStr, InStr);
        SalesCrMemoHeader."QR Code Image".ImportStream(InStr, 'image.png');
        SalesCrMemoHeader.Modify();
    end;

    local procedure InsertCreditMemoHeaderData(var InvoiceXMLNode: XmlElement; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; InvoiceType: Text)
    var
        IDFacturaXMLNode: XmlElement;
    begin
        InvoiceXMLNode.Add(XmlElement.Create('IDVersion', XmlNamespaceSum1, '1.0'));

        IDFacturaXMLNode := XmlElement.Create('IDFactura', XmlNamespaceSum1);
        IDFacturaXMLNode.Add(XmlElement.Create('IDEmisorFactura', XmlNamespaceSum1, CompanyInformation."VAT Registration No."));
        IDFacturaXMLNode.Add(XmlElement.Create('NumSerieFactura', XmlNamespaceSum1, SalesCrMemoHeader."No."));
        IDFacturaXMLNode.Add(XmlElement.Create('FechaExpedicionFactura', XmlNamespaceSum1, FormatDate(SalesCrMemoHeader."Posting Date")));
        InvoiceXMLNode.Add(IDFacturaXMLNode);

        InvoiceXMLNode.Add(XmlElement.Create('NombreRazonEmisor', XmlNamespaceSum1, CompanyInformation."Name"));
        InvoiceXMLNode.Add(XmlElement.Create('TipoFactura', XmlNamespaceSum1, InvoiceType));
        InvoiceXMLNode.Add(XmlElement.Create('TipoRectificativa', XmlNamespaceSum1, 'I'));
        InsertFacturaRectificada(InvoiceXMLNode, SalesCrMemoHeader);
        if SalesCrMemoHeader."Operation Description" = '' then
            SalesCrMemoHeader."Operation Description" := SalesCrMemoHeader."No.";
        InvoiceXMLNode.Add(XmlElement.Create('DescripcionOperacion', XmlNamespaceSum1, SalesCrMemoHeader."Operation Description"));

        InsertRecipient(
            InvoiceXMLNode, SalesCrMemoHeader."Bill-to Name", SalesCrMemoHeader."VAT Registration No.",
            GetRecipientCountryRegionCode(SalesCrMemoHeader."Alt. VAT Registration No.", SalesCrMemoHeader."VAT Country/Region Code", SalesCrMemoHeader."Bill-to Country/Region Code", SalesCrMemoHeader."Sell-to Country/Region Code"),
            SalesCrMemoHeader."ID Type");
    end;

    local procedure InsertCreditMemoBreakdown(var InvoiceXMLNode: XmlElement; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var SalesCrMemoLine: Record "Sales Cr.Memo Line")
    var
        TempSalesCrMemoLine: Record "Sales Cr.Memo Line" temporary;
        DesgloseXMLNode: XmlElement;
        IsIntraCommunity: Boolean;
    begin
        SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
        SalesCrMemoLine.SetFilter(Type, '<>%1', SalesCrMemoLine.Type::" ");
        if SalesCrMemoLine.FindSet() then
            repeat
                if FindLineInTempSalesCrMemoLine(TempSalesCrMemoLine, SalesCrMemoLine) then begin
                    TempSalesCrMemoLine.Amount += SalesCrMemoLine.Amount;
                    TempSalesCrMemoLine."Amount Including VAT" += SalesCrMemoLine."Amount Including VAT";
                    TempSalesCrMemoLine.Modify();
                end else begin
                    TempSalesCrMemoLine.Init();
                    TempSalesCrMemoLine := SalesCrMemoLine;
                    TempSalesCrMemoLine.Insert();
                end;
            until SalesCrMemoLine.Next() = 0;

        DesgloseXMLNode := XmlElement.Create('Desglose', XmlNamespaceSum1);
        IsIntraCommunity := IsIntraCommunityRecipient(GetRecipientCountryRegionCode(SalesCrMemoHeader."Alt. VAT Registration No.", SalesCrMemoHeader."VAT Country/Region Code", SalesCrMemoHeader."Bill-to Country/Region Code", SalesCrMemoHeader."Sell-to Country/Region Code"));

        TempSalesCrMemoLine.Reset();
        TempSalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
        if TempSalesCrMemoLine.FindSet() then
            repeat
                InsertBreakdownDetail(
                    DesgloseXMLNode, SalesCrMemoHeader."No.", SalesCrMemoHeader."Posting Date",
                    GetOptionFirstTwoChars(TempSalesCrMemoLine."Special Scheme Code"), TempSalesCrMemoLine."VAT Bus. Posting Group",
                    TempSalesCrMemoLine."VAT Prod. Posting Group", TempSalesCrMemoLine."VAT Identifier", TempSalesCrMemoLine."VAT %",
                    -TempSalesCrMemoLine.Amount, -(TempSalesCrMemoLine."Amount Including VAT" - TempSalesCrMemoLine.Amount),
                    true, IsIntraCommunity);
            until TempSalesCrMemoLine.Next() = 0;
        TempSalesCrMemoLine.CalcSums(Amount, "Amount Including VAT");

        InvoiceXMLNode.Add(DesgloseXMLNode);
    end;

    local procedure InsertTotals(var InvoiceXMLNode: XmlElement; var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
        InvoiceXMLNode.Add(XmlElement.Create('CuotaTotal', XmlNamespaceSum1, FormatAmount(-(SalesCrMemoHeader."Amount Including VAT" - SalesCrMemoHeader.Amount))));
        InvoiceXMLNode.Add(XmlElement.Create('ImporteTotal', XmlNamespaceSum1, FormatAmount(-SalesCrMemoHeader."Amount Including VAT")));
    end;

    local procedure GenerateHash(SalesCrMemoHeader: Record "Sales Cr.Memo Header"; InvoiceType: Text; VerifactuDateTime: Text; PreviousHuella: Text): Text[64]
    var
        CryptographyManagement: Codeunit "Cryptography Management";
        HashAlgorithmType: Option MD5,SHA1,SHA256,SHA384,SHA512;
        InputString: Text;
    begin
        InputString :=
            'IDEmisorFactura=' + CompanyInformation."VAT Registration No." +
            '&' +
            'NumSerieFactura=' + SalesCrMemoHeader."No." +
            '&' +
            'FechaExpedicionFactura=' + Format(SalesCrMemoHeader."Posting Date", 0, '<Day,2>-<Month,2>-<Year4>') +
            '&' +
            'TipoFactura=' + InvoiceType +
            '&' +
            'CuotaTotal=' + FormatAmount(-(SalesCrMemoHeader."Amount Including VAT" - SalesCrMemoHeader.Amount)) +
            '&' +
            'ImporteTotal=' + FormatAmount(-SalesCrMemoHeader."Amount Including VAT") +
            '&' +
            'Huella=' + PreviousHuella +
            '&' +
            'FechaHoraHusoGenRegistro=' + VerifactuDateTime;
        exit(
            CopyStr(
                CryptographyManagement.GenerateHash(InputString, HashAlgorithmType::SHA256), 1, 64));
    end;

    local procedure FindLineInTempSalesCrMemoLine(var TempSalesCrMemoLine: Record "Sales Cr.Memo Line" temporary; var SalesCrMemoLine: Record "Sales Cr.Memo Line"): Boolean
    begin
        TempSalesCrMemoLine.SetRange("Document No.", SalesCrMemoLine."Document No.");
        TempSalesCrMemoLine.SetRange("VAT %", SalesCrMemoLine."VAT %");
        TempSalesCrMemoLine.SetRange("VAT Bus. Posting Group", SalesCrMemoLine."VAT Bus. Posting Group");
        TempSalesCrMemoLine.SetRange("VAT Prod. Posting Group", SalesCrMemoLine."VAT Prod. Posting Group");
        TempSalesCrMemoLine.SetRange("VAT Identifier", SalesCrMemoLine."VAT Identifier");
        exit(TempSalesCrMemoLine.FindFirst());
    end;

    local procedure InsertFacturaRectificada(var InvoiceXMLNode: XmlElement; var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        FacturaRectificadaXMLNode, IDFacturaRectificadaXMLNode : XmlElement;
    begin
        SalesInvoiceHeader.Get(SalesCrMemoHeader."Corrected Invoice No.");
        FacturaRectificadaXMLNode := XmlElement.Create('FacturasRectificadas', XmlNamespaceSum1);

        IDFacturaRectificadaXMLNode := XmlElement.Create('IDFacturaRectificada', XmlNamespaceSum1);
        IDFacturaRectificadaXMLNode.Add(XmlElement.Create('IDEmisorFactura', XmlNamespaceSum1, CompanyInformation."VAT Registration No."));
        IDFacturaRectificadaXMLNode.Add(XmlElement.Create('NumSerieFactura', XmlNamespaceSum1, SalesInvoiceHeader."No."));
        IDFacturaRectificadaXMLNode.Add(XmlElement.Create('FechaExpedicionFactura', XmlNamespaceSum1, FormatDate(SalesInvoiceHeader."Posting Date")));
        FacturaRectificadaXMLNode.Add(IDFacturaRectificadaXMLNode);

        InvoiceXMLNode.Add(FacturaRectificadaXMLNode);
    end;
    #endregion
    #region Service Credit Memo
    local procedure ExportServiceCreditMemo(var EDocument: Record "E-Document"; var ServiceCrMemoHeader: Record "Service Cr.Memo Header"; var ServiceCrMemoLine: Record "Service Cr.Memo Line"; var TempBlob: Codeunit "Temp Blob"; IsBatch: Boolean)
    var
        HeaderXMLNode, BodyXMLNode, RegFactuSistemaFacturacionXMLNode, RootXMLNode : XmlElement;
        XMLDocOut: XmlDocument;
        FileOutStream: OutStream;
    begin
        TempBlob.CreateOutStream(FileOutStream, TextEncoding::UTF8);

        XmlDocument.ReadFrom(GetBasicXMLHeader(), XMLDocOut);
        XMLDocOut.GetRoot(RootXMLNode);

        InitializeNamespaces();
        HeaderXMLNode := XmlElement.Create('Header', XmlNamespaceSoapenv);
        BodyXMLNode := XmlElement.Create('Body', XmlNamespaceSoapenv);
        RegFactuSistemaFacturacionXMLNode := XmlElement.Create('RegFactuSistemaFacturacion', XmlNamespaceSum);
        InsertHeaderData(RegFactuSistemaFacturacionXMLNode);
        InsertServiceCreditMemosData(RegFactuSistemaFacturacionXMLNode, ServiceCrMemoHeader, ServiceCrMemoLine, IsBatch, EDocument);

        BodyXMLNode.Add(RegFactuSistemaFacturacionXMLNode);
        RootXMLNode.Add(HeaderXMLNode);
        RootXMLNode.Add(BodyXMLNode);

        XmlDocOut.WriteTo(FileOutStream);
    end;

    local procedure InsertServiceCreditMemosData(var RootXMLNode: XmlElement; var ServiceCrMemoHeader: Record "Service Cr.Memo Header"; var ServiceCrMemoLine: Record "Service Cr.Memo Line"; IsBatch: Boolean; var EDocument: Record "E-Document")
    var
        CreditMemoXMLNode: XmlElement;
        CreditMemoCount: Integer;
    begin
        CreditMemoXMLNode := XmlElement.Create('RegistroFactura', XmlNamespaceSum);

        if IsBatch then begin
            ServiceCrMemoHeader.SetAutoCalcFields(Amount, "Amount Including VAT");
            ServiceCrMemoHeader.FindSet();
            repeat
                CreditMemoCount += 1;
                if CreditMemoCount > 1000 then
                    Error(MaxBatchSizeErr);
                InsertServiceCreditMemo(CreditMemoXMLNode, ServiceCrMemoHeader, ServiceCrMemoLine, EDocument);
            until ServiceCrMemoHeader.Next() = 0;
        end else begin
            ServiceCrMemoHeader.CalcFields(Amount, "Amount Including VAT");
            InsertServiceCreditMemo(CreditMemoXMLNode, ServiceCrMemoHeader, ServiceCrMemoLine, EDocument);
        end;
        RootXMLNode.Add(CreditMemoXMLNode);
    end;

    local procedure InsertServiceCreditMemo(var RootXMLNode: XmlElement; var ServiceCrMemoHeader: Record "Service Cr.Memo Header"; var ServiceCrMemoLine: Record "Service Cr.Memo Line"; var EDocument: Record "E-Document")
    var
        TempBlobQR: Codeunit "Temp Blob";
        InvoiceType, VerifactuDateTime : Text;
        PreviousDocumentNo, PreviousHuella : Text;
        VerifactuHash: Text[64];
        PreviousPostingDate: Date;
        CrMemoXMLNode: XmlElement;
        OutStr: OutStream;
        InStr: InStream;
    begin
        InvoiceType := GetOptionFirstTwoChars(ServiceCrMemoHeader."Cr. Memo Type");
        VerifactuDateTime := GetCustomDateTimeFormat(CurrentDateTime());
        FindLastRegisteredDocument(PreviousDocumentNo, PreviousPostingDate, PreviousHuella);
        VerifactuHash := GenerateHash(ServiceCrMemoHeader, InvoiceType, VerifactuDateTime, PreviousHuella);
        VerifactuDocUploadMgt.InsertVerifactuDocument(EDocument, ServiceCrMemoHeader."No.", ServiceCrMemoHeader."Posting Date", VerifactuHash);

        CrMemoXMLNode := XmlElement.Create('RegistroAlta', XmlNamespaceSum1);

        InsertServiceCreditMemoHeaderData(CrMemoXMLNode, ServiceCrMemoHeader, InvoiceType);
        InsertServiceCreditMemoBreakdown(CrMemoXMLNode, ServiceCrMemoHeader, ServiceCrMemoLine);
        InsertTotals(CrMemoXMLNode, ServiceCrMemoHeader);
        InsertRegistroAnterior(CrMemoXMLNode, PreviousDocumentNo, PreviousPostingDate, PreviousHuella);
        InsertInformationSystem(CrMemoXMLNode);
        InsertHuellaDigital(CrMemoXMLNode, VerifactuDateTime, VerifactuHash);

        RootXMLNode.Add(CrMemoXMLNode);

        TempBlobQR := GenerateQRCode(ServiceCrMemoHeader."No.", ServiceCrMemoHeader."Posting Date", ServiceCrMemoHeader."Amount Including VAT");
        TempBlobQR.CreateInStream(InStr);
        ServiceCrMemoHeader."QR Code Base64".CreateOutStream(OutStr, TextEncoding::UTF8);
        CopyStream(OutStr, InStr);
        ServiceCrMemoHeader."QR Code Image".ImportStream(InStr, 'image.png');
        ServiceCrMemoHeader.Modify();
    end;

    local procedure InsertServiceCreditMemoHeaderData(var InvoiceXMLNode: XmlElement; var ServiceCrMemoHeader: Record "Service Cr.Memo Header"; InvoiceType: Text)
    var
        IDFacturaXMLNode: XmlElement;
    begin
        InvoiceXMLNode.Add(XmlElement.Create('IDVersion', XmlNamespaceSum1, '1.0'));

        IDFacturaXMLNode := XmlElement.Create('IDFactura', XmlNamespaceSum1);
        IDFacturaXMLNode.Add(XmlElement.Create('IDEmisorFactura', XmlNamespaceSum1, CompanyInformation."VAT Registration No."));
        IDFacturaXMLNode.Add(XmlElement.Create('NumSerieFactura', XmlNamespaceSum1, ServiceCrMemoHeader."No."));
        IDFacturaXMLNode.Add(XmlElement.Create('FechaExpedicionFactura', XmlNamespaceSum1, FormatDate(ServiceCrMemoHeader."Posting Date")));
        InvoiceXMLNode.Add(IDFacturaXMLNode);

        InvoiceXMLNode.Add(XmlElement.Create('NombreRazonEmisor', XmlNamespaceSum1, CompanyInformation."Name"));
        InvoiceXMLNode.Add(XmlElement.Create('TipoFactura', XmlNamespaceSum1, InvoiceType));
        InvoiceXMLNode.Add(XmlElement.Create('TipoRectificativa', XmlNamespaceSum1, 'I'));
        InsertFacturaRectificada(InvoiceXMLNode, ServiceCrMemoHeader);
        if ServiceCrMemoHeader."Operation Description" = '' then
            ServiceCrMemoHeader."Operation Description" := ServiceCrMemoHeader."No.";
        InvoiceXMLNode.Add(XmlElement.Create('DescripcionOperacion', XmlNamespaceSum1, ServiceCrMemoHeader."Operation Description"));

        InsertRecipient(
            InvoiceXMLNode, ServiceCrMemoHeader."Bill-to Name", ServiceCrMemoHeader."VAT Registration No.",
            GetRecipientCountryRegionCode(false, ServiceCrMemoHeader."VAT Country/Region Code", ServiceCrMemoHeader."Bill-to Country/Region Code", ServiceCrMemoHeader."Country/Region Code"),
            ServiceCrMemoHeader."ID Type");
    end;

    local procedure InsertServiceCreditMemoBreakdown(var InvoiceXMLNode: XmlElement; var ServiceCrMemoHeader: Record "Service Cr.Memo Header"; var ServiceCrMemoLine: Record "Service Cr.Memo Line")
    var
        TempServiceCrMemoLine: Record "Service Cr.Memo Line" temporary;
        DesgloseXMLNode: XmlElement;
        IsIntraCommunity: Boolean;
    begin
        ServiceCrMemoLine.SetRange("Document No.", ServiceCrMemoHeader."No.");
        ServiceCrMemoLine.SetFilter(Type, '<>%1', ServiceCrMemoLine.Type::" ");
        if ServiceCrMemoLine.FindSet() then
            repeat
                if FindLineInTempServiceCrMemoLine(TempServiceCrMemoLine, ServiceCrMemoLine) then begin
                    TempServiceCrMemoLine.Amount += ServiceCrMemoLine.Amount;
                    TempServiceCrMemoLine."Amount Including VAT" += ServiceCrMemoLine."Amount Including VAT";
                    TempServiceCrMemoLine.Modify();
                end else begin
                    TempServiceCrMemoLine.Init();
                    TempServiceCrMemoLine := ServiceCrMemoLine;
                    TempServiceCrMemoLine.Insert();
                end;
            until ServiceCrMemoLine.Next() = 0;

        DesgloseXMLNode := XmlElement.Create('Desglose', XmlNamespaceSum1);
        IsIntraCommunity := IsIntraCommunityRecipient(GetRecipientCountryRegionCode(false, ServiceCrMemoHeader."VAT Country/Region Code", ServiceCrMemoHeader."Bill-to Country/Region Code", ServiceCrMemoHeader."Country/Region Code"));

        TempServiceCrMemoLine.Reset();
        TempServiceCrMemoLine.SetRange("Document No.", ServiceCrMemoHeader."No.");
        if TempServiceCrMemoLine.FindSet() then
            repeat
                InsertBreakdownDetail(
                    DesgloseXMLNode, ServiceCrMemoHeader."No.", ServiceCrMemoHeader."Posting Date",
                    GetOptionFirstTwoChars(TempServiceCrMemoLine."Special Scheme Code"), TempServiceCrMemoLine."VAT Bus. Posting Group",
                    TempServiceCrMemoLine."VAT Prod. Posting Group", TempServiceCrMemoLine."VAT Identifier", TempServiceCrMemoLine."VAT %",
                    -TempServiceCrMemoLine.Amount, -(TempServiceCrMemoLine."Amount Including VAT" - TempServiceCrMemoLine.Amount),
                    true, IsIntraCommunity);
            until TempServiceCrMemoLine.Next() = 0;
        TempServiceCrMemoLine.CalcSums(Amount, "Amount Including VAT");

        InvoiceXMLNode.Add(DesgloseXMLNode);
    end;

    local procedure InsertTotals(var InvoiceXMLNode: XmlElement; var ServiceCrMemoHeader: Record "Service Cr.Memo Header")
    begin
        InvoiceXMLNode.Add(XmlElement.Create('CuotaTotal', XmlNamespaceSum1, FormatAmount(-(ServiceCrMemoHeader."Amount Including VAT" - ServiceCrMemoHeader.Amount))));
        InvoiceXMLNode.Add(XmlElement.Create('ImporteTotal', XmlNamespaceSum1, FormatAmount(-ServiceCrMemoHeader."Amount Including VAT")));
    end;

    local procedure FindLineInTempServiceCrMemoLine(var TempServiceCrMemoLine: Record "Service Cr.Memo Line" temporary; var ServiceCrMemoLine: Record "Service Cr.Memo Line"): Boolean
    begin
        TempServiceCrMemoLine.SetRange("Document No.", ServiceCrMemoLine."Document No.");
        TempServiceCrMemoLine.SetRange("VAT %", ServiceCrMemoLine."VAT %");
        TempServiceCrMemoLine.SetRange("VAT Bus. Posting Group", ServiceCrMemoLine."VAT Bus. Posting Group");
        TempServiceCrMemoLine.SetRange("VAT Prod. Posting Group", ServiceCrMemoLine."VAT Prod. Posting Group");
        TempServiceCrMemoLine.SetRange("VAT Identifier", ServiceCrMemoLine."VAT Identifier");
        exit(TempServiceCrMemoLine.FindFirst());
    end;

    local procedure GenerateHash(ServiceCrMemoHeader: Record "Service Cr.Memo Header"; InvoiceType: Text; VerifactuDateTime: Text; PreviousHuella: Text): Text[64]
    var
        CryptographyManagement: Codeunit "Cryptography Management";
        HashAlgorithmType: Option MD5,SHA1,SHA256,SHA384,SHA512;
        InputString: Text;
    begin
        InputString :=
            'IDEmisorFactura=' + CompanyInformation."VAT Registration No." +
            '&' +
            'NumSerieFactura=' + ServiceCrMemoHeader."No." +
            '&' +
            'FechaExpedicionFactura=' + Format(ServiceCrMemoHeader."Posting Date", 0, '<Day,2>-<Month,2>-<Year4>') +
            '&' +
            'TipoFactura=' + InvoiceType +
            '&' +
            'CuotaTotal=' + FormatAmount(-(ServiceCrMemoHeader."Amount Including VAT" - ServiceCrMemoHeader.Amount)) +
            '&' +
            'ImporteTotal=' + FormatAmount(-ServiceCrMemoHeader."Amount Including VAT") +
            '&' +
            'Huella=' + PreviousHuella +
            '&' +
            'FechaHoraHusoGenRegistro=' + VerifactuDateTime;
        exit(
            CopyStr(
                CryptographyManagement.GenerateHash(InputString, HashAlgorithmType::SHA256), 1, 64));
    end;

    local procedure InsertFacturaRectificada(var InvoiceXMLNode: XmlElement; var ServiceCrMemoHeader: Record "Service Cr.Memo Header")
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        FacturaRectificadaXMLNode, IDFacturaRectificadaXMLNode : XmlElement;
    begin
        ServiceInvoiceHeader.Get(ServiceCrMemoHeader."Corrected Invoice No.");
        FacturaRectificadaXMLNode := XmlElement.Create('FacturasRectificadas', XmlNamespaceSum1);

        IDFacturaRectificadaXMLNode := XmlElement.Create('IDFacturaRectificada', XmlNamespaceSum1);
        IDFacturaRectificadaXMLNode.Add(XmlElement.Create('IDEmisorFactura', XmlNamespaceSum1, CompanyInformation."VAT Registration No."));
        IDFacturaRectificadaXMLNode.Add(XmlElement.Create('NumSerieFactura', XmlNamespaceSum1, ServiceInvoiceHeader."No."));
        IDFacturaRectificadaXMLNode.Add(XmlElement.Create('FechaExpedicionFactura', XmlNamespaceSum1, FormatDate(ServiceInvoiceHeader."Posting Date")));
        FacturaRectificadaXMLNode.Add(IDFacturaRectificadaXMLNode);

        InvoiceXMLNode.Add(FacturaRectificadaXMLNode);
    end;
    #endregion
    #region Common Procedures
    local procedure GenerateQRCode(DocumentNo: Text; DocumentDate: Date; DocumentAmount: Decimal): Codeunit "Temp Blob"
    var
        IBarcodeImageProvider2D: Interface "Barcode Image Provider 2D";
        BarcodeImageProvider2D: Enum "Barcode Image Provider 2D";
        BarcodeString: Text;
    begin
        BarcodeString := CreateQRCodeInput(
            CompanyInformation."VAT Registration No.",
            DocumentNo,
            DocumentDate,
            DocumentAmount);

        IBarcodeImageProvider2D := BarcodeImageProvider2D::Dynamics2D;

        exit(IBarcodeImageProvider2D.EncodeImage(BarcodeString, Enum::"Barcode Symbology 2D"::"QR-Code"));
    end;


    local procedure CreateQRCodeInput(NIF: Text; InvoiceID: Text; DateOfIssue: Date; Amount: Decimal): Text
    begin
        exit(
         VerifactuSetup.GetQRCodeValidationEndpointUrl() +
            'NoVerifactu?nif=' +
            CopyStr(NIF, 1, 13) +
            '&numserie=' +
            CopyStr(InvoiceID, 1, 13) +
            '&fecha=' +
            FormatDate(DateOfIssue) +
            '&importe=' +
            Format(Amount, 0, 9));
    end;

    local procedure InsertHeaderData(var BodyXMLNode: XmlElement)
    var
        CabeceraXMLNode, MandatoryIssuanceXMLNode : XmlElement;
    begin
        CabeceraXMLNode := XmlElement.Create('Cabecera', XmlNamespaceSum);
        MandatoryIssuanceXMLNode := XmlElement.Create('ObligadoEmision', XmlNamespaceSum1);
        MandatoryIssuanceXMLNode.Add(XmlElement.Create('NombreRazon', XmlNamespaceSum1, CompanyInformation.Name));
        MandatoryIssuanceXMLNode.Add(XmlElement.Create('NIF', XmlNamespaceSum1, CompanyInformation."VAT Registration No."));
        CabeceraXMLNode.Add(MandatoryIssuanceXMLNode);
        BodyXMLNode.Add(CabeceraXMLNode);
    end;

    local procedure GetBasicXMLHeader(): Text
    begin
        exit('<?xml version="1.0" encoding="UTF-8"?>' +
            '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" ' +
            'xmlns:sum="https://www2.agenciatributaria.gob.es/static_files/common/internet/dep/aplicaciones/es/aeat/tike/cont/ws/SuministroLR.xsd" ' +
            'xmlns:sum1="https://www2.agenciatributaria.gob.es/static_files/common/internet/dep/aplicaciones/es/aeat/tike/cont/ws/SuministroInformacion.xsd" ' +
            'xmlns:xd="http://www.w3.org/2000/09/xmldsig#" />');
    end;

    local procedure InsertHuellaDigital(var InvoiceXMLNode: XmlElement; VerifactuDateTime: Text; VerifactuHash: Text)
    begin
        InvoiceXMLNode.Add(XmlElement.Create('FechaHoraHusoGenRegistro', XmlNamespaceSum1, VerifactuDateTime));
        InvoiceXMLNode.Add(XmlElement.Create('TipoHuella', XmlNamespaceSum1, '01'));
        InvoiceXMLNode.Add(XmlElement.Create('Huella', XmlNamespaceSum1, VerifactuHash));
    end;

    local procedure InsertRegistroAnterior(var InvoiceXMLNode: XmlElement; PreviousDocumentNo: Text; PreviousPostingDate: Date; PreviousHuella: Text)
    var
        EncadenamientoXMLNode: XmlElement;
    begin
        EncadenamientoXMLNode := XmlElement.Create('Encadenamiento', XmlNamespaceSum1);

        if PreviousHuella <> '' then
            InsertLastRegisteredDocumentData(EncadenamientoXMLNode, PreviousDocumentNo, PreviousPostingDate, PreviousHuella)
        else
            EncadenamientoXMLNode.Add(XmlElement.Create('PrimerRegistro', XmlNamespaceSum1, 'S'));
        InvoiceXMLNode.Add(EncadenamientoXMLNode);
    end;

    local procedure InsertLastRegisteredDocumentData(var EncadenamientoXMLNode: XmlElement; DocumentNo: Text; PostingDate: Date; Huella: Text)
    var
        RegistroAnteriorXMLNode: XmlElement;
    begin
        RegistroAnteriorXMLNode := XmlElement.Create('RegistroAnterior', XmlNamespaceSum1);
        RegistroAnteriorXMLNode.Add(XmlElement.Create('IDEmisorFactura', XmlNamespaceSum1, CompanyInformation."VAT Registration No."));
        RegistroAnteriorXMLNode.Add(XmlElement.Create('NumSerieFactura', XmlNamespaceSum1, DocumentNo));
        RegistroAnteriorXMLNode.Add(XmlElement.Create('FechaExpedicionFactura', XmlNamespaceSum1, FormatDate(PostingDate)));
        RegistroAnteriorXMLNode.Add(XmlElement.Create('Huella', XmlNamespaceSum1, Huella));
        EncadenamientoXMLNode.Add(RegistroAnteriorXMLNode);
    end;

    local procedure InsertInformationSystem(var InvoiceXMLNode: XmlElement)
    var
        SistemaInformacionXMLNode: XmlElement;
    begin
        SistemaInformacionXMLNode := XmlElement.Create('SistemaInformatico', XmlNamespaceSum1);
        SistemaInformacionXMLNode.Add(XmlElement.Create('NombreRazon', XmlNamespaceSum1, CompanyInformation.Name));
        SistemaInformacionXMLNode.Add(XmlElement.Create('NIF', XmlNamespaceSum1, CompanyInformation."VAT Registration No."));
        SistemaInformacionXMLNode.Add(XmlElement.Create('NombreSistemaInformatico', XmlNamespaceSum1, 'BusinessCentral'));
        SistemaInformacionXMLNode.Add(XmlElement.Create('IdSistemaInformatico', XmlNamespaceSum1, '77'));
        SistemaInformacionXMLNode.Add(XmlElement.Create('Version', XmlNamespaceSum1, '1.0'));
        SistemaInformacionXMLNode.Add(XmlElement.Create('NumeroInstalacion', XmlNamespaceSum1, '001'));
        SistemaInformacionXMLNode.Add(XmlElement.Create('TipoUsoPosibleSoloVerifactu', XmlNamespaceSum1, 'N'));
        SistemaInformacionXMLNode.Add(XmlElement.Create('TipoUsoPosibleMultiOT', XmlNamespaceSum1, 'N'));
        SistemaInformacionXMLNode.Add(XmlElement.Create('IndicadorMultiplesOT', XmlNamespaceSum1, 'N'));
        InvoiceXMLNode.Add(SistemaInformacionXMLNode);
    end;

    local procedure FindLastRegisteredDocument(var DocumentNo: Text; var PostingDate: Date; var Huella: Text)
    var
        VerifactuDocument: Record "Verifactu Document";
    begin
        VerifactuDocument.SetLoadFields("Source Document No.", "Verifactu Posting Date", "Verifactu Hash", "Submission Id");
        VerifactuDocument.SetCurrentKey("Submission Id");
        VerifactuDocument.SetFilter("Submission Id", '<>%1', '');
        if not VerifactuDocument.FindLast() then
            exit;

        DocumentNo := VerifactuDocument."Source Document No.";
        PostingDate := VerifactuDocument."Verifactu Posting Date";
        Huella := VerifactuDocument."Verifactu Hash";
    end;

    procedure GetCustomDateTimeFormat(LocalDT: DateTime): Text
    var
        TimeZoneCU: Codeunit "Time Zone";
        TimeZoneOffset: Duration;
        OffsetMinutes: Integer;
        OffsetHours: Integer;
        OffsetSign: Text[1];
        OffsetText: Text;
    begin
        TimeZoneOffset := TimeZoneCU.GetTimezoneOffset(LocalDT, GetTimeZoneFromCompany());

        OffsetMinutes := Abs(TimeZoneOffset div 60000);

        if TimeZoneOffset >= 0 then
            OffsetSign := '+'
        else
            OffsetSign := '-';

        OffsetHours := OffsetMinutes div 60;
        OffsetMinutes := OffsetMinutes mod 60;

        OffsetText := StrSubstNo('%1%2:%3',
            OffsetSign,
            FormatTime(OffsetHours),
            FormatTime(OffsetMinutes));

        exit(
            StrSubstNo('%1%2',
                Format(LocalDT, 0, '<Year4>-<Month,2>-<Day,2>T<Hours24,2>:<Minutes,2>:<Seconds,2>'),
                OffsetText));
    end;

    local procedure GetTimeZoneFromCompany(): Text
    var
        PostCode: Record "Post Code";
        TimeZoneId: Text;
    begin
        if PostCode.Get(CompanyInformation."Post Code", CompanyInformation.City) then
            TimeZoneId := PostCode."Time Zone";
        if TimeZoneId = '' then
            TimeZoneId := 'Romance Standard Time';
        exit(TimeZoneId);
    end;

    local procedure FormatTime(Value: Integer): Text
    begin
        if Value < 10 then
            exit('0' + Format(Value))
        else
            exit(Format(Value));
    end;

    local procedure FormatDate(DateValue: Date): Text
    begin
        exit(Format(DateValue, 0, '<Day,2>-<Month,2>-<Year4>'));
    end;

    local procedure FormatAmount(Amount: Decimal): Text
    begin
        exit(Format(Amount, 0, '<Precision,2:2><Standard Format,9>'));
    end;

    local procedure InsertBreakdownDetail(var DesgloseXMLNode: XmlElement; DocumentNo: Code[20]; PostingDate: Date; SpecialSchemeCode: Text; VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20]; VATIdentifier: Code[20]; VATPercentage: Decimal; BaseAmount: Decimal; VATAmount: Decimal; IsCreditMemo: Boolean; IsIntraCommunity: Boolean)
    var
        DetalleIVAXMLNode: XmlElement;
        OperationQualification: Text;
        ExemptionCode: Text;
    begin
        DetalleIVAXMLNode := XmlElement.Create('DetalleDesglose', XmlNamespaceSum1);
        DetalleIVAXMLNode.Add(XmlElement.Create('ClaveRegimen', XmlNamespaceSum1, SpecialSchemeCode));
        GetVATBreakdownQualification(
            DocumentNo, PostingDate, IsCreditMemo, SpecialSchemeCode, VATBusPostingGroup, VATProdPostingGroup, VATIdentifier,
            VATAmount, IsIntraCommunity, OperationQualification, ExemptionCode);
        AddVATBreakdownNodes(DetalleIVAXMLNode, OperationQualification, ExemptionCode, VATPercentage, BaseAmount, VATAmount);
        DesgloseXMLNode.Add(DetalleIVAXMLNode);
    end;

    local procedure GetVATBreakdownQualification(DocumentNo: Code[20]; PostingDate: Date; IsCreditMemo: Boolean; SpecialSchemeCode: Text; VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20]; VATIdentifier: Code[20]; VATAmount: Decimal; IsIntraCommunity: Boolean; var OperationQualification: Text; var ExemptionCode: Text)
    begin
        OperationQualification := GetOperationQualification(DocumentNo, PostingDate, VATBusPostingGroup, VATProdPostingGroup, VATIdentifier, IsCreditMemo);
        ExemptionCode := '';
        if OperationQualification = 'S1' then
            ExemptionCode := GetExemptionCode(VATBusPostingGroup, VATProdPostingGroup, SpecialSchemeCode, VATAmount, IsIntraCommunity);
    end;

    local procedure AddVATBreakdownNodes(var DetalleIVAXMLNode: XmlElement; OperationQualification: Text; ExemptionCode: Text; VATPercentage: Decimal; BaseAmount: Decimal; VATAmount: Decimal)
    begin
        if ExemptionCode <> '' then begin
            DetalleIVAXMLNode.Add(XmlElement.Create('OperacionExenta', XmlNamespaceSum1, ExemptionCode));
            DetalleIVAXMLNode.Add(XmlElement.Create('BaseImponibleOimporteNoSujeto', XmlNamespaceSum1, Format(BaseAmount, 0, 9)));
            exit;
        end;

        DetalleIVAXMLNode.Add(XmlElement.Create('CalificacionOperacion', XmlNamespaceSum1, OperationQualification));
        if OperationQualification = 'S1' then
            DetalleIVAXMLNode.Add(XmlElement.Create('TipoImpositivo', XmlNamespaceSum1, Format(VATPercentage, 0, 9)));
        DetalleIVAXMLNode.Add(XmlElement.Create('BaseImponibleOimporteNoSujeto', XmlNamespaceSum1, Format(BaseAmount, 0, 9)));
        if OperationQualification = 'S1' then
            DetalleIVAXMLNode.Add(XmlElement.Create('CuotaRepercutida', XmlNamespaceSum1, Format(VATAmount, 0, 9)));
    end;

    local procedure GetExemptionCode(VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20]; SpecialSchemeCode: Text; VATAmount: Decimal; IsIntraCommunity: Boolean): Text
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATClause: Record "VAT Clause";
        ExportSpecialSchemeCodeTok: Label '02', Locked = true;
    begin
        if not VATPostingSetup.Get(VATBusPostingGroup, VATProdPostingGroup) then
            exit('');

        if VATPostingSetup."VAT Clause Code" <> '' then
            if VATClause.Get(VATPostingSetup."VAT Clause Code") then
                case VATClause."SII Exemption Code" of
                    VATClause."SII Exemption Code"::"E1 Exempt on account of Article 20":
                        exit('E1');
                    VATClause."SII Exemption Code"::"E2 Exempt on account of Article 21":
                        exit('E2');
                    VATClause."SII Exemption Code"::"E3 Exempt on account of Article 22":
                        exit('E3');
                    VATClause."SII Exemption Code"::"E4 Exempt under Articles 23 and 24":
                        exit('E4');
                    VATClause."SII Exemption Code"::"E5 Exempt on account of Article 25":
                        exit('E5');
                    VATClause."SII Exemption Code"::"E6 Exempt on other grounds":
                        exit('E6');
                end;

        // Without an explicit exemption code, untaxed exports and intra-community supplies of goods are exempt under Art. 21 and Art. 25.
        if VATAmount <> 0 then
            exit('');
        if SpecialSchemeCode = ExportSpecialSchemeCodeTok then
            exit('E2');
        if IsIntraCommunity and (not VATPostingSetup."EU Service") and
           (VATPostingSetup."VAT Calculation Type" = VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT")
        then
            exit('E5');
        exit('');
    end;

    local procedure InsertRecipient(var InvoiceXMLNode: XmlElement; RecipientName: Text; VATRegistrationNo: Text[20]; CountryRegionCode: Code[10]; IDType: Enum "SII ID Type")
    var
        DestinatariosXMLNode, IDDestinatarioXMLNode, IDOtroXMLNode : XmlElement;
        UseNIF: Boolean;
        CountryCode, IDTypeCode, ID : Text;
    begin
        GetRecipientIdentification(CountryRegionCode, VATRegistrationNo, IDType, UseNIF, CountryCode, IDTypeCode, ID);

        DestinatariosXMLNode := XmlElement.Create('Destinatarios', XmlNamespaceSum1);
        IDDestinatarioXMLNode := XmlElement.Create('IDDestinatario', XmlNamespaceSum1);
        IDDestinatarioXMLNode.Add(XmlElement.Create('NombreRazon', XmlNamespaceSum1, RecipientName));
        if UseNIF then
            IDDestinatarioXMLNode.Add(XmlElement.Create('NIF', XmlNamespaceSum1, ID))
        else begin
            IDOtroXMLNode := XmlElement.Create('IDOtro', XmlNamespaceSum1);
            if CountryCode <> '' then
                IDOtroXMLNode.Add(XmlElement.Create('CodigoPais', XmlNamespaceSum1, CountryCode));
            IDOtroXMLNode.Add(XmlElement.Create('IDType', XmlNamespaceSum1, IDTypeCode));
            IDOtroXMLNode.Add(XmlElement.Create('ID', XmlNamespaceSum1, ID));
            IDDestinatarioXMLNode.Add(IDOtroXMLNode);
        end;
        DestinatariosXMLNode.Add(IDDestinatarioXMLNode);
        InvoiceXMLNode.Add(DestinatariosXMLNode);
    end;

    local procedure GetRecipientIdentification(CountryRegionCode: Code[10]; VATRegistrationNo: Text[20]; IDType: Enum "SII ID Type"; var UseNIF: Boolean; var CountryCode: Text; var IDTypeCode: Text; var ID: Text)
    var
        CountryRegion: Record "Country/Region";
        SIIManagement: Codeunit "SII Management";
        VATRegistrationNoIDTypeTok: Label '02', Locked = true;
    begin
        ID := VATRegistrationNo;
        UseNIF := SIIManagement.CountryAndVATRegNoAreLocal(CountryRegionCode, VATRegistrationNo);
        if not UseNIF then begin
            IDTypeCode := GetRecipientIDTypeCode(IDType, SIIManagement.IsIntracommunity(CountryRegionCode));
            if CountryRegion.Get(CountryRegionCode) and (CountryRegion."ISO Code" <> '') then
                CountryCode := CountryRegion."ISO Code"
            else
                CountryCode := CountryRegionCode;
            if IDTypeCode = VATRegistrationNoIDTypeTok then begin
                // CodigoPais is optional for NIF-IVA, and Northern Ireland (XI) is not a valid AEAT country code.
                if SIIManagement.CountryIsNorthernIreland(CountryRegionCode) then
                    CountryCode := '';
                ID := GetVATRegistrationNoWithPrefix(CountryRegion, CountryRegionCode, VATRegistrationNo);
            end;
        end;
    end;

    local procedure GetRecipientIDTypeCode(IDType: Enum "SII ID Type"; IsIntraCommunity: Boolean): Text
    begin
        case IDType of
            "SII ID Type"::"02-VAT Registration No.":
                exit('02');
            "SII ID Type"::"03-Passport":
                exit('03');
            "SII ID Type"::"04-ID Document":
                exit('04');
            "SII ID Type"::"05-Certificate Of Residence":
                exit('05');
            "SII ID Type"::"06-Other Probative Document":
                exit('06');
            "SII ID Type"::"07-Not On The Census":
                exit('07');
        end;

        if IsIntraCommunity then
            exit('02');
        exit('04');
    end;

    local procedure GetVATRegistrationNoWithPrefix(CountryRegion: Record "Country/Region"; CountryRegionCode: Code[10]; VATRegistrationNo: Text[20]): Text
    var
        Prefix: Text;
    begin
        Prefix := CountryRegion."EU Country/Region Code";
        if Prefix = '' then
            Prefix := CountryRegion."ISO Code";
        if Prefix = '' then
            Prefix := CountryRegionCode;
        if (Prefix = '') or (VATRegistrationNo = '') or VATRegistrationNo.StartsWith(Prefix) then
            exit(VATRegistrationNo);
        // AEAT limits ID to 20 characters; never truncate the identifier.
        if StrLen(Prefix + VATRegistrationNo) > MaxStrLen(VATRegistrationNo) then
            exit(VATRegistrationNo);
        exit(Prefix + VATRegistrationNo);
    end;

    local procedure GetRecipientCountryRegionCode(AltVATRegistrationNo: Boolean; VATCountryRegionCode: Code[10]; BillToCountryRegionCode: Code[10]; SellToCountryRegionCode: Code[10]): Code[10]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // VAT Country/Region Code follows the ship-to country; it only identifies the recipient when an alternative VAT registration was used.
        if AltVATRegistrationNo and (VATCountryRegionCode <> '') then
            exit(VATCountryRegionCode);

        GeneralLedgerSetup.SetLoadFields("Bill-to/Sell-to VAT Calc.");
        if GeneralLedgerSetup.Get() then
            if GeneralLedgerSetup."Bill-to/Sell-to VAT Calc." = GeneralLedgerSetup."Bill-to/Sell-to VAT Calc."::"Sell-to/Buy-from No." then
                exit(SellToCountryRegionCode);
        exit(BillToCountryRegionCode);
    end;

    local procedure IsIntraCommunityRecipient(RecipientCountryRegionCode: Code[10]): Boolean
    var
        SIIManagement: Codeunit "SII Management";
    begin
        exit(SIIManagement.IsIntracommunity(RecipientCountryRegionCode));
    end;

    local procedure GetOperationQualification(DocumentNo: Code[20]; PostingDate: Date; VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20]; VATIdentifier: Code[20]; IsCreditMemo: Boolean): Text
    var
        NoTaxableEntry: Record "No Taxable Entry";
    begin
        NoTaxableEntry.SetLoadFields("No Taxable Type");
        NoTaxableEntry.SetRange(Type, NoTaxableEntry.Type::Sale);
        if IsCreditMemo then
            NoTaxableEntry.SetRange("Document Type", NoTaxableEntry."Document Type"::"Credit Memo")
        else
            NoTaxableEntry.SetRange("Document Type", NoTaxableEntry."Document Type"::Invoice);
        NoTaxableEntry.SetRange("Document No.", DocumentNo);
        NoTaxableEntry.SetRange("Posting Date", PostingDate);
        NoTaxableEntry.SetRange("VAT Bus. Posting Group", VATBusPostingGroup);
        NoTaxableEntry.SetRange("VAT Prod. Posting Group", VATProdPostingGroup);
        NoTaxableEntry.SetRange(Reversed, false);
        if NoTaxableEntry.FindFirst() then
            case NoTaxableEntry."No Taxable Type" of
                NoTaxableEntry."No Taxable Type"::"Non Taxable Art 7-14 and others":
                    exit('N1');
                NoTaxableEntry."No Taxable Type"::"Non Taxable Due To Localization Rules":
                    exit('N2');
            end;

        exit(GetVATIdentifier(VATIdentifier));
    end;

    local procedure GetVATIdentifier(VATIdentifier: Code[20]): Text
    begin
        if VATIdentifier = '' then
            exit('N1')
        else
            exit('S1');
    end;

    local procedure GetOptionFirstTwoChars(OptionValue: Variant): Text[2]
    var
        OptionString: Text;
    begin
        OptionString := Format(OptionValue);
        exit(CopyStr(OptionString, 1, 2));
    end;

    local procedure InitializeNamespaces()
    begin
        XmlNamespaceSoapenv := 'http://schemas.xmlsoap.org/soap/envelope/';
        XmlNamespaceSum := 'https://www2.agenciatributaria.gob.es/static_files/common/internet/dep/aplicaciones/es/aeat/tike/cont/ws/SuministroLR.xsd';
        XmlNamespaceSum1 := 'https://www2.agenciatributaria.gob.es/static_files/common/internet/dep/aplicaciones/es/aeat/tike/cont/ws/SuministroInformacion.xsd';
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