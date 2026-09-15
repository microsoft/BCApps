// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

using System.Environment;
using System.Security.Encryption;

codeunit 10146 "EInvoice Communication"
{
    var
        EInvoiceCommunication: Interface "EInvoice Communication V2";
        LastUsedCertificateSN: Text;
        LastUsedCert: Text;
        Initialized: Boolean;


    /// <summary>
    /// Sends request to PAC service with a specific method.
    /// </summary>
    /// <param name="Uri">Uri of the service</param>
    /// <param name="MethodName">Method name</param>
    /// <param name="CertBase64">PAC certificate as base64</param>
    /// <param name="CertPassword">Certificate password</param>
    /// <returns>Response as a string.</returns>
    [NonDebuggable]
    procedure InvokeMethodWithCertificate(Uri: Text; MethodName: Text; CertBase64: Text; CertPassword: SecretText): Text
    begin
        Init();
        exit(EInvoiceCommunication.InvokeMethodWithCertificate(Uri, MethodName, CertBase64, CertPassword));
    end;

    /// <summary>
    /// Signs data before sending it to PAC service.
    /// </summary>
    /// <param name="OriginalString">String to sign</param>
    /// <param name="CertBase64">SAT certificate as base64</param>
    /// <param name="CertPassword">Certificate password</param>
    /// <returns>Signed data as a string.</returns>
    [NonDebuggable]
    procedure SignDataWithCertificate(OriginalString: Text; CertBase64: Text; CertPassword: SecretText): Text
    var
        X509Certificate2: Codeunit X509Certificate2;
        TempCert: Text;
    begin
        Init();
        X509Certificate2.GetCertificateSerialNumberAsASCII(CertBase64, CertPassword, LastUsedCertificateSN);

        TempCert := CertBase64;
        if X509Certificate2.VerifyCertificate(TempCert, CertPassword, Enum::"X509 Content Type"::Cert) then
            LastUsedCert := TempCert;

        exit(EInvoiceCommunication.SignDataWithCertificate(OriginalString, CertBase64, CertPassword));
    end;

    /// <summary>
    /// Adds a parameter to the request.
    /// </summary>
    /// <param name="Parameter">Parameter that accepts different data type like string, or boolean</param>
    procedure AddParameters(Parameter: Variant);
    begin
        Init();
        EInvoiceCommunication.AddParameters(Parameter);
    end;

    /// <summary>
    /// Gets last used certificate serial number.
    /// </summary>
    /// <returns>Last used certificate.</returns>
    procedure LastUsedCertificateSerialNo(): Text
    begin
        exit(LastUsedCertificateSN);
    end;

    /// <summary>
    /// Gets last used certificate.
    /// </summary>
    /// <returns>Last used certificate.</returns>
    procedure LastUsedCertificate(): Text
    begin
        exit(LastUsedCert);
    end;

    local procedure Init()
    var
        EnvironmentInfo: Codeunit "Environment Information";
        EInvoiceSaaSCommunication: Codeunit "EInvoice SaaS Communication";
        EInvoiceOnPremCommunication: Codeunit "EInvoice OnPrem Communication";
    begin
        if Initialized then
            exit;

        if EnvironmentInfo.IsSaaS() then
            EInvoiceCommunication := EInvoiceSaaSCommunication
        else
            EInvoiceCommunication := EInvoiceOnPremCommunication;

        Initialized := true;
    end;
}