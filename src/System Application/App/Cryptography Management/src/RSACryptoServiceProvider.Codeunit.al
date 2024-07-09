// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Security.Encryption;

/// <summary>
/// Performs asymmetric encryption and decryption using the implementation of the RSA algorithm provided by the cryptographic service provider (CSP).
/// </summary>
codeunit 1445 RSACryptoServiceProvider
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        RSACryptoServiceProviderImpl: Codeunit "RSACryptoServiceProvider Impl.";

    /// <summary>
    /// Initializes a new instance of RSACryptoServiceProvider with the specified key size and returns the key as an XML string.
    /// </summary>
    /// <param name="KeySize">The size of the key in bits.</param>
    procedure InitializeRSA(KeySize: Integer)
    begin
        RSACryptoServiceProviderImpl.InitializeRSA(KeySize);
    end;

#if not CLEAN24
    /// <summary>
    /// Creates and returns an XML string containing the key of the current RSA object.
    /// </summary>
    /// <param name="IncludePrivateParameters">true to include a public and private RSA key; false to include only the public key.</param>
    /// <returns>An XML string containing the key of the current RSA object.</returns>
    [Obsolete('Use ToSecretXmlString with SecretText data type for XmlString or use PublicKeyToXmlString to retrieve the public key as Text.', '24.0')]
    procedure ToXmlString(IncludePrivateParameters: Boolean): Text
    begin
#pragma warning disable AL0432
        exit(RSACryptoServiceProviderImpl.ToXmlString(IncludePrivateParameters));
#pragma warning restore AL0432
    end;

    /// <summary>
    /// Computes the hash value of the specified data and signs it.
    /// </summary>
    /// <param name="XmlString">The XML string containing RSA key information.</param>
    /// <param name="DataInStream">The input stream to hash and sign.</param>
    /// <param name="HashAlgorithm">The hash algorithm to use to create the hash value.</param>
    /// <param name="SignatureOutStream">The RSA signature stream for the specified data.</param>
    [NonDebuggable]
    [Obsolete('Use SignData with SecretText data type for XmlString.', '24.0')]
    procedure SignData(XmlString: Text; DataInStream: InStream; HashAlgorithm: Enum "Hash Algorithm"; SignatureOutStream: OutStream)
    begin
        RSACryptoServiceProviderImpl.SignData(XmlString, DataInStream, HashAlgorithm, SignatureOutStream);
    end;

    /// <summary>
    /// Verifies that a digital signature is valid by determining the hash value in the signature using the provided public key and comparing it to the hash value of the provided data.
    /// </summary>
    /// <param name="XmlString">The XML string containing RSA key information.</param>
    /// <param name="DataInStream">The input stream of data that was signed.</param>
    /// <param name="HashAlgorithm">The name of the hash algorithm used to create the hash value of the data.</param>
    /// <param name="SignatureInStream">The stream of signature data to be verified.</param>
    /// <returns>True if the signature is valid; otherwise, false.</returns>
    [NonDebuggable]
    [Obsolete('Use VerifyData with SecretText data type for XmlString.', '24.0')]
    procedure VerifyData(XmlString: Text; DataInStream: InStream; HashAlgorithm: Enum "Hash Algorithm"; SignatureInStream: InStream): Boolean
    begin
        exit(RSACryptoServiceProviderImpl.VerifyData(XmlString, DataInStream, HashAlgorithm, SignatureInStream));
    end;

    /// <summary>
    /// Encrypts the specified text with the RSA algorithm.
    /// </summary>
    /// <param name="XmlString">The XML string containing RSA key information.</param>
    /// <param name="PlainTextInStream">The input stream to encrypt.</param>
    /// <param name="OaepPadding">True to perform RSA encryption using OAEP padding; otherwise, false to use PKCS#1 padding.</param>
    /// <param name="EncryptedTextOutStream">The RSA encryption stream for the specified text.</param>
    [Obsolete('Use Encrypt with SecretText data type for XmlString.', '24.0')]
    procedure Encrypt(XmlString: Text; PlainTextInStream: InStream; OaepPadding: Boolean; EncryptedTextOutStream: OutStream)
    begin
        RSACryptoServiceProviderImpl.Encrypt(XmlString, PlainTextInStream, OaepPadding, EncryptedTextOutStream);
    end;

    /// <summary>
    /// Decrypts the specified text that was previously encrypted with the RSA algorithm.
    /// </summary>
    /// <param name="XmlString">The XML string containing RSA key information.</param>
    /// <param name="EncryptedTextInStream">The input stream to decrypt.</param>
    /// <param name="OaepPadding">true to perform RSA encryption using OAEP padding; otherwise, false to use PKCS#1 padding.</param>
    /// <param name="DecryptedTextOutStream">The RSA decryption stream for the specified text.</param>
    [NonDebuggable]
    [Obsolete('Use Decrypt with SecretText data type for XmlString.', '24.0')]
    procedure Decrypt(XmlString: Text; EncryptedTextInStream: InStream; OaepPadding: Boolean; DecryptedTextOutStream: OutStream)
    begin
        RSACryptoServiceProviderImpl.Decrypt(XmlString, EncryptedTextInStream, OaepPadding, DecryptedTextOutStream);
    end;
#endif

    /// <summary>
    /// Creates and returns an XML string containing the public key of the current RSA object.
    /// </summary>
    /// <returns>An XML string containing the public key of the current RSA object.</returns>
    procedure PublicKeyToXmlString(): Text
    begin
        exit(RSACryptoServiceProviderImpl.PublicKeyToXmlString());
    end;

    /// <summary>
    /// Creates and returns an XML string containing the key of the current RSA object.
    /// </summary>
    /// <param name="IncludePrivateParameters">true to include a public and private RSA key; false to include only the public key.</param>
    /// <returns>An XML string containing the key of the current RSA object.</returns>
    procedure ToSecretXmlString(IncludePrivateParameters: Boolean): SecretText
    begin
        exit(RSACryptoServiceProviderImpl.ToSecretXmlString(IncludePrivateParameters));
    end;

    /// <summary>
    /// Computes the hash value of the specified data and signs it.
    /// </summary>
    /// <param name="XmlString">The XML string containing RSA key information.</param>
    /// <param name="DataInStream">The input stream to hash and sign.</param>
    /// <param name="HashAlgorithm">The hash algorithm to use to create the hash value.</param>
    /// <param name="SignatureOutStream">The RSA signature stream for the specified data.</param>
    procedure SignData(XmlString: SecretText; DataInStream: InStream; HashAlgorithm: Enum "Hash Algorithm"; SignatureOutStream: OutStream)
    begin
        RSACryptoServiceProviderImpl.SignData(XmlString, DataInStream, HashAlgorithm, SignatureOutStream);
    end;

    /// <summary>
    /// Verifies that a digital signature is valid by determining the hash value in the signature using the provided public key and comparing it to the hash value of the provided data.
    /// </summary>
    /// <param name="XmlString">The XML string containing RSA key information.</param>
    /// <param name="DataInStream">The input stream of data that was signed.</param>
    /// <param name="HashAlgorithm">The name of the hash algorithm used to create the hash value of the data.</param>
    /// <param name="SignatureInStream">The stream of signature data to be verified.</param>
    /// <returns>True if the signature is valid; otherwise, false.</returns>
    procedure VerifyData(XmlString: SecretText; DataInStream: InStream; HashAlgorithm: Enum "Hash Algorithm"; SignatureInStream: InStream): Boolean
    begin
        exit(RSACryptoServiceProviderImpl.VerifyData(XmlString, DataInStream, HashAlgorithm, SignatureInStream));
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
        RSACryptoServiceProviderImpl.Encrypt(XmlString, PlainTextInStream, OaepPadding, EncryptedTextOutStream);
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
        RSACryptoServiceProviderImpl.Decrypt(XmlString, EncryptedTextInStream, OaepPadding, DecryptedTextOutStream);
    end;

    /// <summary>  
    /// The CreateRSAKeyPair procedure is a function that generates a public and private RSA key pair.  
    /// </summary>  
    /// <param name="PublicKeyInXml">This is an output parameter that returns the public key in XML format.</param>  
    /// <param name="PrivateKeyInXml">This is an output parameter that returns the private key in XML format. This is a sensitive information hence marked as SecretText.</param>  
    /// <returns>  
    /// This function does not return a value. The output is via the two parameters PublicKeyInXml and PrivateKeyInXml.  
    /// </returns>  
    procedure CreateRSAKeyPair(var PublicKeyInXml: Text; var PrivateKeyInXml: SecretText)
    begin
        RSACryptoServiceProviderImpl.CreateRSAKeyPair(PublicKeyInXml, PrivateKeyInXml);
    end;
}