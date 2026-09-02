// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 3308 "Digital Sign MX"
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
        XmlString: Text;
    begin
        XMLDoc.WriteTo(XmlString);
        exit(XmlString);
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