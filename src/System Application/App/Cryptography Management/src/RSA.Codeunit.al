// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Security.Encryption;

/// <summary>
/// Performs asymmetric encryption and digital signature using the implementation of the RSA class.
/// </summary>
codeunit 1475 "RSA"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        RSAImpl: Codeunit "RSA Impl.";

    /// <summary>
    /// Initializes a new instance of RSA with the specified key size.
    /// </summary>
    /// <param name="KeySize">The size of the key in bits.</param>
    procedure InitializeRSA(KeySize: Integer)
    begin
        RSAImpl.InitializeRSA(KeySize);
    end;

    /// <summary>
    /// Creates and returns an XML string containing the key of the current RSA object.
    /// </summary>
    /// <param name="IncludePrivateParameters">true to include a public and private RSA key; false to include only the public key.</param>
    /// <returns>An XML string containing the key of the current RSA object.</returns>
    procedure ToSecretXmlString(IncludePrivateParameters: Boolean): SecretText
    begin
        exit(RSAImpl.ToSecretXmlString(IncludePrivateParameters));
    end;

    /// <summary>
    /// Computes the hash value of the specified data and signs it.
    /// </summary>
    /// <param name="XmlString">The XML string containing RSA key information.</param>
    /// <param name="DataInStream">The input stream to hash and sign.</param>
    /// <param name="HashAlgorithm">The hash algorithm to use to create the hash value.</param>
    /// <param name="RSASignaturePadding">The padding mode to use for the RSA signature.</param>
    /// <param name="SignatureOutStream">The RSA signature stream for the specified data.</param>
    procedure SignData(XmlString: SecretText; DataInStream: InStream; HashAlgorithm: Enum "Hash Algorithm"; RSASignaturePadding: Enum "RSA Signature Padding"; SignatureOutStream: OutStream)
    begin
        RSAImpl.SignData(XmlString, DataInStream, HashAlgorithm, RSASignaturePadding, SignatureOutStream);
    end;

    /// <summary>
    /// Verifies that a digital signature is valid by determining the hash value in the signature using the provided public key and comparing it to the hash value of the provided data.
    /// </summary>
    /// <param name="XmlString">The XML string containing RSA key information.</param>
    /// <param name="DataInStream">The input stream of data that was signed.</param>
    /// <param name="HashAlgorithm">The name of the hash algorithm used to create the hash value of the data.</param>
    /// <param name="RSASignaturePadding">The padding mode to use for the RSA signature.</param>
    /// <param name="SignatureInStream">The stream of signature data to be verified.</param>
    /// <returns>True if the signature is valid; otherwise, false.</returns>
    procedure VerifyData(XmlString: SecretText; DataInStream: InStream; HashAlgorithm: Enum "Hash Algorithm"; RSASignaturePadding: Enum "RSA Signature Padding"; SignatureInStream: InStream): Boolean
    begin
        exit(RSAImpl.VerifyData(XmlString, DataInStream, HashAlgorithm, RSASignaturePadding, SignatureInStream));
    end;

    /// <summary>
    /// Encrypts the specified text with the RSA algorithm.
    /// </summary>
    /// <param name="XmlString">The XML string containing RSA key information.</param>
    /// <param name="PlainTextInStream">The input stream to encrypt.</param>
    /// <param name="OaepPadding">True to perform RSA encryption using OAEP padding; otherwise, false to use PKCS#1 padding.</param>
    /// <param name="EncryptedTextOutStream">The RSA encryption stream for the specified text.</param>
    procedure Encrypt(XmlString: SecretText; PlainTextInStream: InStream; OaepPadding: Boolean; EncryptedTextOutStream: OutStream)
    begin
        RSAImpl.Encrypt(XmlString, PlainTextInStream, OaepPadding, EncryptedTextOutStream);
    end;

    /// <summary>
    /// Decrypts the specified text that was previously encrypted with the RSA algorithm.
    /// </summary>
    /// <param name="XmlString">The XML string containing RSA key information.</param>
    /// <param name="EncryptedTextInStream">The input stream to decrypt.</param>
    /// <param name="OaepPadding">true to perform RSA encryption using OAEP padding; otherwise, false to use PKCS#1 padding.</param>
    /// <param name="DecryptedTextOutStream">The RSA decryption stream for the specified text.</param>
    procedure Decrypt(XmlString: SecretText; EncryptedTextInStream: InStream; OaepPadding: Boolean; DecryptedTextOutStream: OutStream)
    begin
        RSAImpl.Decrypt(XmlString, EncryptedTextInStream, OaepPadding, DecryptedTextOutStream);
    end;
}