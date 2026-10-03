// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance;

using System.Security.Encryption;

/// <summary>
/// Codeunit for signing plain text data used to generate the PKP (Podpisový kód poplatníka) control code.
/// In EET 2.0 (interface version 4.x), the PKP control code is no longer part of the data message.
/// The EET 2.0 data message (element Trzba) no longer requires a taxpayer signature code (PKP)
/// as part of its structure - the message is secured solely by the WS-Security XML signature
/// of the SOAP envelope. The service confirms receipt by returning only the POK (Potvrzovací kód).
/// This codeunit is kept for backward compatibility but is not used in the EET 2.0 communication flow.
/// </summary>
codeunit 31081 "EET Text Sign. Provider CZL"
{
    Access = Internal;

    [NonDebuggable]
    procedure SignData(DataText: Text; IsolatedCertificate: Record "Isolated Certificate"; SignatureOutStream: OutStream)
    var
        CertificateManagement: Codeunit "Certificate Management";
        SignatureKey: Codeunit "Signature Key";
    begin
        CertificateManagement.GetCertPrivateKey(IsolatedCertificate, SignatureKey);
        SignData(DataText, SignatureKey, SignatureOutStream);
    end;

    [NonDebuggable]
    procedure SignData(DataText: Text; SignatureKey: Codeunit "Signature Key"; SignatureOutStream: OutStream)
    var
        CryptographyManagement: Codeunit "Cryptography Management";
    begin
        CryptographyManagement.SignData(DataText, SignatureKey, Enum::"Hash Algorithm"::SHA256, SignatureOutStream);
    end;
}
