// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance;

using System.Security.Encryption;
using System.Text;
using System.Utilities;

/// <summary>
/// Codeunit for generating EET control codes (PKP - Podpisový kód poplatníka and BKP - Bezpečnostní kód poplatníka).
/// In EET 2.0 (interface version 4.x), these control codes are no longer part of the data message structure.
/// The EET 2.0 service returns only POK (Potvrzovací kód) as confirmation of a successfully received transaction.
/// The data message (element Trzba) in EET 2.0 contains only Hlavicka and Data elements without PKP/BKP codes.
/// This codeunit is kept for backward compatibility but is not used in the EET 2.0 communication flow.
/// </summary>
codeunit 31099 "EET Control Codes Mgt. CZL"
{
    Access = Internal;

    var
        TempBlob: Codeunit "Temp Blob";
        BlobInStream: InStream;
        BlobOutStream: OutStream;
        SecurityCodeTok: Label '%1-%2-%3-%4-%5', Locked = true;
        SignatureCodePlainTextTok: Label '%1|%2|%3|%4|%5|%6', Locked = true;

    [NonDebuggable]
    procedure GenerateSignatureCode(EETEntryCZL: Record "EET Entry CZL"): Text
    var
        IsolatedCertificate: Record "Isolated Certificate";
        CertificateCodeCZL: Record "Certificate Code CZL";
        Base64Convert: Codeunit "Base64 Convert";
    begin
        CertificateCodeCZL.Get(EETEntryCZL.GetCertificateCode());
        if not CertificateCodeCZL.FindValidCertificate(IsolatedCertificate) then
            exit;

        InitBlob();
        SignText(GenerateSignatureCodeAsPlainText(EETEntryCZL), IsolatedCertificate, BlobOutStream);
        exit(Base64Convert.ToBase64(BlobInStream));
    end;

    [NonDebuggable]
    procedure GenerateSecurityCode(SignatureCode: Text): Text[44]
    var
        CryptographyManagement: Codeunit "Cryptography Management";
        Base64Convert: Codeunit "Base64 Convert";
        HashAlgorithmType: Option MD5,SHA1,SHA256,SHA384,SHA512;
        Hash: Text;
    begin
        if SignatureCode = '' then
            exit;

        InitBlob();
        Base64Convert.FromBase64(SignatureCode, BlobOutStream);
        Hash := CryptographyManagement.GenerateHash(BlobInStream, HashAlgorithmType::SHA1);
        exit(
            StrSubstNo(SecurityCodeTok,
                CopyStr(Hash, 1, 8), CopyStr(Hash, 9, 8), CopyStr(Hash, 17, 8),
                CopyStr(Hash, 25, 8), CopyStr(Hash, 33, 8)));
    end;

    local procedure GenerateSignatureCodeAsPlainText(EETEntryCZL: Record "EET Entry CZL"): Text
    var
        EETServiceManagementCZL: Codeunit "EET Service Management CZL";
    begin
        exit(
            StrSubstNo(SignatureCodePlainTextTok,
                EETEntryCZL."VAT Registration No.",
                EETEntryCZL.GetBusinessPremisesId(),
                EETEntryCZL."Cash Register Code",
                EETEntryCZL."Receipt Serial No.",
                EETServiceManagementCZL.FormatDateTime(EETEntryCZL."Created At"),
                EETServiceManagementCZL.FormatDecimal(EETEntryCZL."Total Sales Amount")));
    end;

    [NonDebuggable]
    local procedure SignText(InputString: Text; IsolatedCertificate: Record "Isolated Certificate"; SignatureOutStream: OutStream)
    var
        EETTextSignProviderCZL: Codeunit "EET Text Sign. Provider CZL";
    begin
        EETTextSignProviderCZL.SignData(InputString, IsolatedCertificate, SignatureOutStream);
    end;

    local procedure InitBlob()
    begin
        Clear(TempBlob);
        TempBlob.CreateInStream(BlobInStream);
        TempBlob.CreateOutStream(BlobOutStream);
    end;
}
