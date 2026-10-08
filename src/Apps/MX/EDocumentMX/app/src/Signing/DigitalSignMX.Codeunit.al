// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.EServices.EDocument.Interfactura;

using Microsoft.EServices.EDocument;
using System.Security.Encryption;

codeunit 3358 "Digital Sign MX"
{
    var
        EInvoiceCommunication: Codeunit "EInvoice Communication";
        LastUsedCertificateSN: Text;
        LastUsedCert: Text;

    procedure CreateOriginalString(XMLDoc: XmlDocument): Text
    var
        XmlString: Text;
    begin
        XMLDoc.WriteTo(XmlString);
        exit(XmlString);
    end;

    procedure CreatePaymentOriginalString(XMLDoc: XmlDocument): Text
    var
        XmlText: Text;
        OriginalString: Text;
        Position: Integer;
    begin
        // Build the pipe-delimited cadena original per SAT cadenaoriginal_Pagos20.xslt.
        // Attributes are emitted in the SAT-mandated order for each element type,
        // regardless of their serialization order in the XML.
        XMLDoc.WriteTo(XmlText);
        OriginalString := '||';
        Position := 1;
        while Position <= StrLen(XmlText) do
            if CopyStr(XmlText, Position, 1) = '<' then begin
                Position += 1;
                if Position > StrLen(XmlText) then
                    break;
                if (CopyStr(XmlText, Position, 1) = '/') or
                   (CopyStr(XmlText, Position, 1) = '?') or
                   (CopyStr(XmlText, Position, 1) = '!')
                then
                    PayCO_SkipToTagEnd(XmlText, Position)
                else
                    PayCO_AppendTag(XmlText, Position, OriginalString);
            end else
                Position += 1;
        exit(OriginalString + '|');
    end;

    local procedure PayCO_AppendTag(XmlText: Text; var Position: Integer; var OriginalString: Text)
    var
        ElementName: Text;
        TagAttrStart: Integer;
    begin
        PayCO_ReadElementName(XmlText, Position, ElementName);
        TagAttrStart := Position;

        case LowerCase(PayCO_LocalName(ElementName)) of
            'comprobante':
                begin
                    // SAT cadenaoriginal_Pagos20.xslt Comprobante order; Sello/Certificado are excluded.
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'Version');
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'Serie');
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'Folio');
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'Fecha');
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'NoCertificado');
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'SubTotal');
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'Moneda');
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'Total');
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'TipoDeComprobante');
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'Exportacion');
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'LugarExpedicion');
                end;
            'emisor':
                begin
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'Rfc');
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'Nombre');
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'RegimenFiscal');
                end;
            'receptor':
                begin
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'Rfc');
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'Nombre');
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'DomicilioFiscalReceptor');
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'ResidenciaFiscal');
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'NumRegIdTrib');
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'RegimenFiscalReceptor');
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'UsoCFDI');
                end;
            'concepto':
                begin
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'ClaveProdServ');
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'NoIdentificacion');
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'Cantidad');
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'ClaveUnidad');
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'Unidad');
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'Descripcion');
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'ValorUnitario');
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'Importe');
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'Descuento');
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'ObjetoImp');
                end;
            'pagos':
                PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'Version');
            'totales':
                begin
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'TotalRetencionesIVA');
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'TotalRetencionesISR');
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'TotalRetencionesIEPS');
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'TotalTrasladosBaseIVA16');
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'TotalTrasladosImpuestoIVA16');
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'TotalTrasladosBaseIVA8');
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'TotalTrasladosImpuestoIVA8');
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'TotalTrasladosBaseIVA0');
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'TotalTrasladosImpuestoIVA0');
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'TotalTrasladosBaseIVAExento');
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'MontoTotalPagos');
                end;
            'pago':
                begin
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'FechaPago');
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'FormaDePagoP');
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'MonedaP');
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'TipoCambioP');
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'Monto');
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'NumOperacion');
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'RfcEmisorCtaOrd');
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'NomBancoOrdExt');
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'CtaOrdenante');
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'RfcEmisorCtaBen');
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'CtaBeneficiario');
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'TipoCadPago');
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'CertPago');
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'CadPago');
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'SelloPago');
                end;
            'doctorelacionado':
                begin
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'IdDocumento');
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'Serie');
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'Folio');
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'MonedaDR');
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'EquivalenciaDR');
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'NumParcialidad');
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'ImpSaldoAnt');
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'ImpPagado');
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'ImpSaldoInsoluto');
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'ObjetoImpDR');
                end;
            'trasladodr':
                begin
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'BaseDR');
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'ImpuestoDR');
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'TipoFactorDR');
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'TasaOCuotaDR');
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'ImporteDR');
                end;
            'retenciondr':
                begin
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'BaseDR');
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'ImpuestoDR');
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'TipoFactorDR');
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'TasaOCuotaDR');
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'ImporteDR');
                end;
            'trasladop':
                begin
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'BaseP');
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'ImpuestoP');
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'TipoFactorP');
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'TasaOCuotaP');
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'ImporteP');
                end;
            'retencionp':
                begin
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'ImpuestoP');
                    PayCO_AppendAttr(XmlText, TagAttrStart, OriginalString, 'ImporteP');
                end;
        end;

        PayCO_SkipToTagEnd(XmlText, Position);
    end;

    // Searches the tag starting at TagAttrStart for AttributeName (case-insensitive)
    // and appends its normalized value to OriginalString.
    local procedure PayCO_AppendAttr(XmlText: Text; TagAttrStart: Integer; var OriginalString: Text; AttributeName: Text)
    var
        SearchPosition: Integer;
        CurrAttrName: Text;
        CurrAttrValue: Text;
    begin
        SearchPosition := TagAttrStart;
        while SearchPosition <= StrLen(XmlText) do begin
            PayCO_SkipWhiteSpaces(XmlText, SearchPosition);
            if SearchPosition > StrLen(XmlText) then
                exit;
            if (CopyStr(XmlText, SearchPosition, 1) = '>') or (CopyStr(XmlText, SearchPosition, 2) = '/>') then
                exit;

            PayCO_ReadAttrName(XmlText, SearchPosition, CurrAttrName);
            if CurrAttrName = '' then begin
                SearchPosition += 1;
                continue;
            end;

            PayCO_SkipWhiteSpaces(XmlText, SearchPosition);
            if CopyStr(XmlText, SearchPosition, 1) <> '=' then begin
                SearchPosition += 1;
                continue;
            end;
            SearchPosition += 1;
            PayCO_SkipWhiteSpaces(XmlText, SearchPosition);
            PayCO_ReadAttrValue(XmlText, SearchPosition, CurrAttrValue);

            if LowerCase(CurrAttrName) = LowerCase(AttributeName) then begin
                PayCO_EmitValue(CurrAttrValue, OriginalString);
                exit;
            end;
        end;
    end;

    local procedure PayCO_EmitValue(Value: Text; var OriginalString: Text)
    var
        I: Integer;
        C: Text[1];
        PrevSpace: Boolean;
        Normalized: Text;
    begin
        // Decode XML entities, strip pipes, collapse whitespace (mirrors NormalizeOriginalStringValue).
        Value := Value.Replace('&quot;', '"');
        Value := Value.Replace('&apos;', '''');
        Value := Value.Replace('&lt;', '<');
        Value := Value.Replace('&gt;', '>');
        Value := Value.Replace('&amp;', '&');
        Value := DelChr(Value, '=', '|');
        Value := DelChr(Value, '<>', ' ');
        for I := 1 to StrLen(Value) do begin
            C := CopyStr(Value, I, 1);
            if C = ' ' then begin
                if not PrevSpace then begin
                    Normalized += C;
                    PrevSpace := true;
                end;
            end else begin
                Normalized += C;
                PrevSpace := false;
            end;
        end;
        if Normalized <> '' then
            OriginalString += Normalized + '|';
    end;

    local procedure PayCO_ReadElementName(XmlText: Text; var Position: Integer; var ElementName: Text)
    var
        Start: Integer;
    begin
        Start := Position;
        while Position <= StrLen(XmlText) do
            if PayCO_IsWhiteSpace(CopyStr(XmlText, Position, 1)) or
               (CopyStr(XmlText, Position, 1) = '>') or
               (CopyStr(XmlText, Position, 1) = '/')
            then
                break
            else
                Position += 1;
        ElementName := CopyStr(XmlText, Start, Position - Start);
    end;

    local procedure PayCO_ReadAttrName(XmlText: Text; var Position: Integer; var AttrName: Text)
    var
        Start: Integer;
    begin
        Start := Position;
        while Position <= StrLen(XmlText) do
            if PayCO_IsWhiteSpace(CopyStr(XmlText, Position, 1)) or
               (CopyStr(XmlText, Position, 1) = '=') or
               (CopyStr(XmlText, Position, 1) = '>') or
               (CopyStr(XmlText, Position, 1) = '/')
            then
                break
            else
                Position += 1;
        AttrName := CopyStr(XmlText, Start, Position - Start);
    end;

    local procedure PayCO_ReadAttrValue(XmlText: Text; var Position: Integer; var AttrValue: Text)
    var
        QuoteChar: Text[1];
        Start: Integer;
    begin
        AttrValue := '';
        if Position > StrLen(XmlText) then
            exit;
        QuoteChar := CopyStr(XmlText, Position, 1);
        if (QuoteChar = '"') or (QuoteChar = '''') then begin
            Position += 1;
            Start := Position;
            while (Position <= StrLen(XmlText)) and (CopyStr(XmlText, Position, 1) <> QuoteChar) do
                Position += 1;
            AttrValue := CopyStr(XmlText, Start, Position - Start);
            if Position <= StrLen(XmlText) then
                Position += 1;
            exit;
        end;
        Start := Position;
        while Position <= StrLen(XmlText) do
            if PayCO_IsWhiteSpace(CopyStr(XmlText, Position, 1)) or
               (CopyStr(XmlText, Position, 1) = '>') or
               (CopyStr(XmlText, Position, 1) = '/')
            then
                break
            else
                Position += 1;
        AttrValue := CopyStr(XmlText, Start, Position - Start);
    end;

    local procedure PayCO_SkipToTagEnd(XmlText: Text; var Position: Integer)
    begin
        while (Position <= StrLen(XmlText)) and (CopyStr(XmlText, Position, 1) <> '>') do
            Position += 1;
        if Position <= StrLen(XmlText) then
            Position += 1;
    end;

    local procedure PayCO_SkipWhiteSpaces(XmlText: Text; var Position: Integer)
    begin
        while (Position <= StrLen(XmlText)) and PayCO_IsWhiteSpace(CopyStr(XmlText, Position, 1)) do
            Position += 1;
    end;

    local procedure PayCO_IsWhiteSpace(C: Text[1]): Boolean
    begin
        exit((C = ' ') or (C = Format(9)) or (C = Format(10)) or (C = Format(13)));
    end;

    local procedure PayCO_LocalName(ElementName: Text): Text
    var
        ColonPos: Integer;
    begin
        ColonPos := StrPos(ElementName, ':');
        if ColonPos = 0 then
            exit(ElementName);
        exit(CopyStr(ElementName, ColonPos + 1));
    end;

    procedure CreateDigitalSignature(OriginalString: Text; SetupId: Code[10]): Text
    var
        MXConnectionSetup: Record "MX Connection Setup";
        IsolatedCertificate: Record "Isolated Certificate";
        CertificateManagement: Codeunit "Certificate Management";
        CertBase64: Text;
        CertPassword: SecretText;
        SignedString: Text;
    begin
        if not MXConnectionSetup.Get(SetupId) then
            Error('MX Connection Setup %1 not found.', SetupId);

        if MXConnectionSetup."SAT Certificate" = '' then
            Error('SAT Certificate is not configured in MX Connection Setup.');

        if not IsolatedCertificate.Get(MXConnectionSetup."SAT Certificate") then
            Error('SAT certificate %1 not found.', MXConnectionSetup."SAT Certificate");



        CertBase64 := CertificateManagement.GetCertAsBase64String(IsolatedCertificate);
        CertPassword := CertificateManagement.GetPasswordAsSecret(IsolatedCertificate);

        if CertBase64 = '' then
            Error('SAT certificate is empty.');

        LastUsedCert := CertBase64;

        if not SignDataWithCert(SignedString, OriginalString, CertBase64, CertPassword, LastUsedCertificateSN) then
            Error('Unable to sign the CFDI with the SAT certificate: %1', GetLastErrorText());

        if SignedString = '' then
            Error('Unable to sign the CFDI with the SAT certificate: the generated digital stamp is empty. Verify that the SAT certificate includes its private key and that the password is correct.');

        exit(SignedString);
    end;

    [TryFunction]
    local procedure SignDataWithCert(var SignedString: Text; OriginalString: Text; Certificate: Text; Password: SecretText; var SerialNoOfCertificateUsed: Text)
    begin
        SignedString := EInvoiceCommunication.SignDataWithCertificate(OriginalString, Certificate, Password);
        SerialNoOfCertificateUsed := CopyStr(EInvoiceCommunication.LastUsedCertificateSerialNo(), 1, MaxStrLen(SerialNoOfCertificateUsed));
        LastUsedCert := EInvoiceCommunication.LastUsedCertificate();
        LastUsedCertificateSN := SerialNoOfCertificateUsed;
    end;

    procedure InvokeStampRequest(SetupId: Code[10]; RequestXml: Text): Text
    var
        MXConnectionSetup: Record "MX Connection Setup";
        PACWebServiceDetail: Record "MX PAC Web Service Detail";
        IsolatedCertificate: Record "Isolated Certificate";
        CertificateManagement: Codeunit "Certificate Management";
        CertBase64: Text;
        CertPassword: SecretText;
    begin
        if not MXConnectionSetup.Get(SetupId) then
            Error('MX Connection Setup %1 not found.', SetupId);

        if not PACWebServiceDetail.Get(SetupId, PACWebServiceDetail.Type::"Request Stamp") then
            Error('PAC web service detail for stamp request is missing.');

        if PACWebServiceDetail.Address = '' then
            Error('PAC address is empty for Request Stamp.');

        if PACWebServiceDetail."Method Name" = '' then
            Error('PAC method name is empty for Request Stamp.');

        if MXConnectionSetup."PAC Certificate" = '' then
            Error('PAC Certificate is not configured in MX Connection Setup.');

        if not IsolatedCertificate.Get(MXConnectionSetup."PAC Certificate") then
            Error('PAC certificate %1 not found.', MXConnectionSetup."PAC Certificate");

        CertBase64 := CertificateManagement.GetCertAsBase64String(IsolatedCertificate);
        CertPassword := CertificateManagement.GetPasswordAsSecret(IsolatedCertificate);

        EInvoiceCommunication.AddParameters(RequestXml);
        exit(EInvoiceCommunication.InvokeMethodWithCertificate(PACWebServiceDetail.Address,
            PACWebServiceDetail."Method Name", CertBase64, CertPassword));
    end;

    procedure GetLastUsedCertificate(): Text
    begin
        exit(LastUsedCert);
    end;

    procedure GetLastUsedCertificateSerialNo(): Text
    begin
        exit(LastUsedCertificateSN);
    end;

    procedure GetCertificateSerialNo(SetupId: Code[10]): Text[250]
    var
        MXConnectionSetup: Record "MX Connection Setup";
        IsolatedCertificate: Record "Isolated Certificate";
        CertificateManagement: Codeunit "Certificate Management";
        CertBase64: Text;
        CertPassword: SecretText;
        X509Certificate2: Codeunit X509Certificate2;
    begin
        if not MXConnectionSetup.Get(SetupId) then
            Error('MX Connection Setup %1 not found.', SetupId);

        if MXConnectionSetup."SAT Certificate" = '' then
            exit('');

        if not IsolatedCertificate.Get(MXConnectionSetup."SAT Certificate") then
            Error('SAT certificate %1 not found.', MXConnectionSetup."SAT Certificate");

        CertBase64 := CertificateManagement.GetCertAsBase64String(IsolatedCertificate);
        CertPassword := CertificateManagement.GetPasswordAsSecret(IsolatedCertificate);

        if CertBase64 <> '' then begin
            X509Certificate2.GetCertificateSerialNumberAsASCII(CertBase64, CertPassword, LastUsedCertificateSN);
            LastUsedCert := CertBase64;
        end;

        exit(CopyStr(LastUsedCertificateSN, 1, 250));
    end;

    procedure GetCertificateInfo(SetupId: Code[10]; var SerialNo: Text; var NotBefore: DateTime; var NotAfter: DateTime)
    var
        MXConnectionSetup: Record "MX Connection Setup";
        IsolatedCertificate: Record "Isolated Certificate";
        CertificateManagement: Codeunit "Certificate Management";
        CertBase64: Text;
        CertPassword: SecretText;
        X509Certificate2: Codeunit X509Certificate2;
    begin
        SerialNo := '';
        NotBefore := 0DT;
        NotAfter := 0DT;

        if not MXConnectionSetup.Get(SetupId) then
            exit;

        if MXConnectionSetup."SAT Certificate" = '' then
            exit;

        if not IsolatedCertificate.Get(MXConnectionSetup."SAT Certificate") then
            exit;

        CertBase64 := CertificateManagement.GetCertAsBase64String(IsolatedCertificate);
        CertPassword := CertificateManagement.GetPasswordAsSecret(IsolatedCertificate);

        if CertBase64 <> '' then begin
            X509Certificate2.GetCertificateSerialNumberAsASCII(CertBase64, CertPassword, SerialNo);
            LastUsedCertificateSN := SerialNo;
            LastUsedCert := CertBase64;
        end;
    end;
}