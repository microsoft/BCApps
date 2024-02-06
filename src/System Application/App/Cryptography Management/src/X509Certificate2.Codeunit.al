// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Security.Encryption;

/// <summary>
/// Provides helper functions to work with the X509Certificate2 class.
/// </summary>
codeunit 1286 X509Certificate2
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        X509Certificate2Impl: Codeunit "X509Certificate2 Impl.";

#if not CLEAN24
    /// <summary>
    /// Verifes that a certificate is initialized and can be exported.
    /// </summary>
    /// <param name="CertBase64Value">Represents the certificate value encoded using the Base64 algorithm</param>
    /// <param name="Password">Certificate Password</param>
    /// <param name="X509ContentType">Specifies the format of an X.509 certificate</param>
    /// <returns>True if certificate is verified</returns>
    /// <error>When certificate cannot be initialized</error>
    /// <error>When certificate cannot be exported</error>
    [NonDebuggable]
    [Obsolete('Use VerifyCertificate with SecretText data type for Password.', '24.0')]
    procedure VerifyCertificate(var CertBase64Value: Text; Password: Text; X509ContentType: Enum "X509 Content Type"): Boolean
    begin
        exit(X509Certificate2Impl.VerifyCertificate(CertBase64Value, Password, X509ContentType));
    end;

    /// <summary>
    /// Specifies the friendly name of the certificate based on it's Base64 value.
    /// </summary>
    /// <param name="CertBase64Value">Represents the certificate value encoded using the Base64 algorithm</param>
    /// <param name="Password">Certificate Password</param>
    /// <param name="FriendlyName">Represents certificate Friendly Name</param>
    [NonDebuggable]
    [Obsolete('Use GetCertificateFriendlyName with SecretText data type for Password.', '24.0')]
    procedure GetCertificateFriendlyName(CertBase64Value: Text; Password: Text; var FriendlyName: Text)
    begin
        X509Certificate2Impl.GetCertificateFriendlyName(CertBase64Value, Password, FriendlyName);
    end;

    /// <summary>
    /// Specifies the subject of the certificate based on it's Base64 value.
    /// </summary>
    /// <param name="CertBase64Value">Represents the certificate value encoded using the Base64 algorithm</param>
    /// <param name="Password">Certificate Password</param>
    /// <param name="Subject">Certificate subject distinguished name</param>
    [NonDebuggable]
    [Obsolete('Use GetCertificateSubject with SecretText data type for Password.', '24.0')]
    procedure GetCertificateSubject(CertBase64Value: Text; Password: Text; var Subject: Text)
    begin
        X509Certificate2Impl.GetCertificateSubject(CertBase64Value, Password, Subject);
    end;

    /// <summary>
    /// Specifies the thumbprint of the certificate based on it's Base64 value.
    /// </summary>
    /// <param name="CertBase64Value">Represents the certificate value encoded using the Base64 algorithm</param>
    /// <param name="Password">Certificate Password</param>
    /// <param name="Thumbprint">Certificate Thumbprint</param>
    [NonDebuggable]
    [Obsolete('Use GetCertificateThumbprint with SecretText data type for Password.', '24.0')]
    procedure GetCertificateThumbprint(CertBase64Value: Text; Password: Text; var Thumbprint: Text)
    begin
        X509Certificate2Impl.GetCertificateThumbprint(CertBase64Value, Password, Thumbprint);
    end;

    /// <summary>
    /// Specifies the issuer of the certificate based on it's Base64 value.
    /// </summary>
    /// <param name="CertBase64Value">Represents the certificate value encoded using the Base64 algorithm</param>
    /// <param name="Password">Certificate Password</param>
    /// <param name="Issuer">Certificate Issuer</param>
    [NonDebuggable]
    [Obsolete('Use GetCertificateIssuer with SecretText data type for Password.', '24.0')]
    procedure GetCertificateIssuer(CertBase64Value: Text; Password: Text; var Issuer: Text)
    begin
        X509Certificate2Impl.GetCertificateIssuer(CertBase64Value, Password, Issuer);
    end;

    /// <summary>
    /// Specifies the expiration date of the certificate based on it's Base64 value.
    /// </summary>
    /// <param name="CertBase64Value">Represents the certificate value encoded using the Base64 algorithm</param>
    /// <param name="Password">Certificate Password</param>
    /// <param name="Expiration">Certificate Expiration Date</param>
    [NonDebuggable]
    [Obsolete('Use GetCertificateExpiration with SecretText data type for Password.', '24.0')]
    procedure GetCertificateExpiration(CertBase64Value: Text; Password: Text; var Expiration: DateTime)
    begin
        X509Certificate2Impl.GetCertificateExpiration(CertBase64Value, Password, Expiration);
    end;

    /// <summary>
    /// Specifies the NotBefore date of the certificate based on it's Base64 value.
    /// </summary>
    /// <param name="CertBase64Value">Represents the certificate value encoded using the Base64 algorithm</param>
    /// <param name="Password">Certificate Password</param>
    /// <param name="NotBefore">Certificate NotBefore Date</param>
    [NonDebuggable]
    [Obsolete('Use GetCertificateNotBefore with SecretText data type for Password.', '24.0')]
    procedure GetCertificateNotBefore(CertBase64Value: Text; Password: Text; var NotBefore: DateTime)
    begin
        X509Certificate2Impl.GetCertificateNotBefore(CertBase64Value, Password, NotBefore);
    end;

    /// <summary>
    /// Checks whether the certificate has a private key based on it's Base64 value.
    /// </summary>
    /// <param name="CertBase64Value">Represents the certificate value encoded using the Base64 algorithm</param>
    /// <param name="Password">Certificate Password</param>
    /// <returns>True if the certificate has private key</returns>
    [NonDebuggable]
    [Obsolete('Use HasPrivateKey with SecretText data type for Password.', '24.0')]
    procedure HasPrivateKey(CertBase64Value: Text; Password: Text): Boolean
    begin
        exit(X509Certificate2Impl.HasPrivateKey(CertBase64Value, Password));
    end;

    /// <summary>
    /// Specifies the certificate details in Json object
    /// </summary>
    /// <param name="CertBase64Value">Represents the certificate value encoded using the Base64 algorithm</param>
    /// <param name="Password">Certificate Password</param>
    /// <param name="CertPropertyJson">Certificate details in json</param>
    [NonDebuggable]
    [Obsolete('Use GetCertificatePropertiesAsJson with SecretText data type for Password.', '24.0')]
    procedure GetCertificatePropertiesAsJson(CertBase64Value: Text; Password: Text; var CertPropertyJson: Text)
    begin
        X509Certificate2Impl.GetCertificatePropertiesAsJson(CertBase64Value, Password, CertPropertyJson);
    end;

    /// <summary>
    /// Gets Certificate public key
    /// </summary>
    /// <param name="CertBase64Value">Represents the certificate value encoded using the Base64 algorithm</param>
    /// <param name="Password">Certificate Password</param>
    [NonDebuggable]
    [Obsolete('Use GetCertificatePublicKey with SecretText data type for Password.', '24.0')]
    procedure GetCertificatePublicKey(CertBase64Value: Text; Password: Text): Text
    begin
        exit(X509Certificate2Impl.GetCertificatePublicKey(CertBase64Value, Password));
    end;

    /// <summary>
    /// Gets Certificate private key
    /// </summary>
    /// <param name="CertBase64Value">Represents the certificate value encoded using the Base64 algorithm</param>
    /// <param name="Password">Certificate Password</param>
    [NonDebuggable]
    [Obsolete('Use GetCertificatePrivateKey with SecretText data type for Password and return value.', '24.0')]
    procedure GetCertificatePrivateKey(CertBase64Value: Text; Password: Text): Text
    begin
#pragma warning disable AL0432
        exit(X509Certificate2Impl.GetCertificatePrivateKey(CertBase64Value, Password));
#pragma warning restore AL0432
    end;

    /// <summary>
    /// Gets Certificate serial number
    /// </summary>
    /// <param name="CertBase64Value">Represents the certificate value encoded using the Base64 algorithm</param>
    /// <param name="Password">Certificate Password</param>
    /// <param name="SerialNumber">Certificate serial number</param>
    [NonDebuggable]
    [Obsolete('Use GetCertificateSerialNumber with SecretText data type for Password.', '24.0')]
    procedure GetCertificateSerialNumber(CertBase64Value: Text; Password: Text; var SerialNumber: Text)
    begin
        X509Certificate2Impl.GetCertificateSerialNumber(CertBase64Value, Password, SerialNumber);
    end;

    /// <summary>
    /// Gets Certificate serial number as ASCII
    /// </summary>
    /// <param name="CertBase64Value">Represents the certificate value encoded using the Base64 algorithm</param>
    /// <param name="Password">Certificate Password</param>
    /// <param name="SerialNumberASCII">Certificate serial number as ascii</param>
    [NonDebuggable]
    [Obsolete('Use GetCertificateSerialNumberAsASCII with SecretText data type for Password.', '24.0')]
    procedure GetCertificateSerialNumberAsASCII(CertBase64Value: Text; Password: Text; var SerialNumberASCII: Text)
    begin
        X509Certificate2Impl.GetCertificateSerialNumberAsASCII(CertBase64Value, Password, SerialNumberASCII);
    end;
#endif

    /// <summary>
    /// Verifes that a certificate is initialized and can be exported.
    /// </summary>
    /// <param name="CertBase64Value">Represents the certificate value encoded using the Base64 algorithm</param>
    /// <param name="Password">Certificate Password</param>
    /// <param name="X509ContentType">Specifies the format of an X.509 certificate</param>
    /// <returns>True if certificate is verified</returns>
    /// <error>When certificate cannot be initialized</error>
    /// <error>When certificate cannot be exported</error>
    procedure VerifyCertificate(var CertBase64Value: Text; Password: SecretText; X509ContentType: Enum "X509 Content Type"): Boolean
    begin
        exit(X509Certificate2Impl.VerifyCertificate(CertBase64Value, Password, X509ContentType));
    end;

    /// <summary>
    /// Specifies the friendly name of the certificate based on it's Base64 value.
    /// </summary>
    /// <param name="CertBase64Value">Represents the certificate value encoded using the Base64 algorithm</param>
    /// <param name="Password">Certificate Password</param>
    /// <param name="FriendlyName">Represents certificate Friendly Name</param>
    procedure GetCertificateFriendlyName(CertBase64Value: Text; Password: SecretText; var FriendlyName: Text)
    begin
        X509Certificate2Impl.GetCertificateFriendlyName(CertBase64Value, Password, FriendlyName);
    end;

    /// <summary>
    /// Specifies the subject of the certificate based on it's Base64 value.
    /// </summary>
    /// <param name="CertBase64Value">Represents the certificate value encoded using the Base64 algorithm</param>
    /// <param name="Password">Certificate Password</param>
    /// <param name="Subject">Certificate subject distinguished name</param>
    procedure GetCertificateSubject(CertBase64Value: Text; Password: SecretText; var Subject: Text)
    begin
        X509Certificate2Impl.GetCertificateSubject(CertBase64Value, Password, Subject);
    end;

    /// <summary>
    /// Specifies the thumbprint of the certificate based on it's Base64 value.
    /// </summary>
    /// <param name="CertBase64Value">Represents the certificate value encoded using the Base64 algorithm</param>
    /// <param name="Password">Certificate Password</param>
    /// <param name="Thumbprint">Certificate Thumbprint</param>
    procedure GetCertificateThumbprint(CertBase64Value: Text; Password: SecretText; var Thumbprint: Text)
    begin
        X509Certificate2Impl.GetCertificateThumbprint(CertBase64Value, Password, Thumbprint);
    end;

    /// <summary>
    /// Specifies the issuer of the certificate based on it's Base64 value.
    /// </summary>
    /// <param name="CertBase64Value">Represents the certificate value encoded using the Base64 algorithm</param>
    /// <param name="Password">Certificate Password</param>
    /// <param name="Issuer">Certificate Issuer</param>
    procedure GetCertificateIssuer(CertBase64Value: Text; Password: SecretText; var Issuer: Text)
    begin
        X509Certificate2Impl.GetCertificateIssuer(CertBase64Value, Password, Issuer);
    end;

    /// <summary>
    /// Specifies the expiration date of the certificate based on it's Base64 value.
    /// </summary>
    /// <param name="CertBase64Value">Represents the certificate value encoded using the Base64 algorithm</param>
    /// <param name="Password">Certificate Password</param>
    /// <param name="Expiration">Certificate Expiration Date</param>
    procedure GetCertificateExpiration(CertBase64Value: Text; Password: SecretText; var Expiration: DateTime)
    begin
        X509Certificate2Impl.GetCertificateExpiration(CertBase64Value, Password, Expiration);
    end;

    /// <summary>
    /// Specifies the NotBefore date of the certificate based on it's Base64 value.
    /// </summary>
    /// <param name="CertBase64Value">Represents the certificate value encoded using the Base64 algorithm</param>
    /// <param name="Password">Certificate Password</param>
    /// <param name="NotBefore">Certificate NotBefore Date</param>
    procedure GetCertificateNotBefore(CertBase64Value: Text; Password: SecretText; var NotBefore: DateTime)
    begin
        X509Certificate2Impl.GetCertificateNotBefore(CertBase64Value, Password, NotBefore);
    end;

    /// <summary>
    /// Checks whether the certificate has a private key based on it's Base64 value.
    /// </summary>
    /// <param name="CertBase64Value">Represents the certificate value encoded using the Base64 algorithm</param>
    /// <param name="Password">Certificate Password</param>
    /// <returns>True if the certificate has private key</returns>
    procedure HasPrivateKey(CertBase64Value: Text; Password: SecretText): Boolean
    begin
        exit(X509Certificate2Impl.HasPrivateKey(CertBase64Value, Password));
    end;

    /// <summary>
    /// Specifies the certificate details in Json object
    /// </summary>
    /// <param name="CertBase64Value">Represents the certificate value encoded using the Base64 algorithm</param>
    /// <param name="Password">Certificate Password</param>
    /// <param name="CertPropertyJson">Certificate details in json</param>
    procedure GetCertificatePropertiesAsJson(CertBase64Value: Text; Password: SecretText; var CertPropertyJson: Text)
    begin
        X509Certificate2Impl.GetCertificatePropertiesAsJson(CertBase64Value, Password, CertPropertyJson);
    end;

    /// <summary>
    /// Gets Certificate public key
    /// </summary>
    /// <param name="CertBase64Value">Represents the certificate value encoded using the Base64 algorithm</param>
    /// <param name="Password">Certificate Password</param>
    procedure GetCertificatePublicKey(CertBase64Value: Text; Password: SecretText): Text
    begin
        exit(X509Certificate2Impl.GetCertificatePublicKey(CertBase64Value, Password));
    end;

    /// <summary>
    /// Gets Certificate private key
    /// </summary>
    /// <param name="CertBase64Value">Represents the certificate value encoded using the Base64 algorithm</param>
    /// <param name="Password">Certificate Password</param>
    procedure GetCertificatePrivateKey(CertBase64Value: Text; Password: SecretText): SecretText
    begin
        exit(X509Certificate2Impl.GetSecretCertificatePrivateKey(CertBase64Value, Password));
    end;

    /// <summary>
    /// Gets Certificate serial number
    /// </summary>
    /// <param name="CertBase64Value">Represents the certificate value encoded using the Base64 algorithm</param>
    /// <param name="Password">Certificate Password</param>
    /// <param name="SerialNumber">Certificate serial number</param>
    procedure GetCertificateSerialNumber(CertBase64Value: Text; Password: SecretText; var SerialNumber: Text)
    begin
        X509Certificate2Impl.GetCertificateSerialNumber(CertBase64Value, Password, SerialNumber);
    end;

    /// <summary>
    /// Gets Certificate serial number as ASCII
    /// </summary>
    /// <param name="CertBase64Value">Represents the certificate value encoded using the Base64 algorithm</param>
    /// <param name="Password">Certificate Password</param>
    /// <param name="SerialNumberASCII">Certificate serial number as ascii</param>
    procedure GetCertificateSerialNumberAsASCII(CertBase64Value: Text; Password: SecretText; var SerialNumberASCII: Text)
    begin
        X509Certificate2Impl.GetCertificateSerialNumberAsASCII(CertBase64Value, Password, SerialNumberASCII);
    end;
}