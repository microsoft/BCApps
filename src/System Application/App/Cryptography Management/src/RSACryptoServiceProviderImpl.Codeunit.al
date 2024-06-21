// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Security.Encryption;

using System;

#if not CLEAN24
#pragma warning disable AL0432
codeunit 1446 "RSACryptoServiceProvider Impl." implements SignatureAlgorithm, "Signature Algorithm v2"
#pragma warning restore AL0432
#else
codeunit 1446 "RSACryptoServiceProvider Impl." implements "Signature Algorithm v2"
#endif
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        DotNetRSACryptoServiceProvider: DotNet RSACryptoServiceProvider;

    procedure InitializeRSA(KeySize: Integer)
    begin
        DotNetRSACryptoServiceProvider := DotNetRSACryptoServiceProvider.RSACryptoServiceProvider(KeySize);
    end;

    procedure GetInstance(var DotNetAsymmetricAlgorithm: DotNet AsymmetricAlgorithm)
    begin
        DotNetAsymmetricAlgorithm := DotNetRSACryptoServiceProvider;
    end;

    [NonDebuggable]
    procedure CreateRSAKeyPair(var PublicKeyInXml: Text; var PrivateKeyInXml: SecretText)
    var
        DotnetRSA: DotNet RSA;
    begin
        RSACryptoServiceProvider();
        DotnetRSA := DotNetRSACryptoServiceProvider.Create();
        PublicKeyInXml := DotnetRSA.ToXmlString(false);
        PrivateKeyInXml := DotnetRSA.ToXmlString(true);
    end;

    #region SignData
    procedure SignData(XmlString: SecretText; DataInStream: InStream; HashAlgorithm: Enum "Hash Algorithm"; SignatureOutStream: OutStream)
    begin
        FromSecretXmlString(XmlString);
        SignData(DataInStream, HashAlgorithm, SignatureOutStream);
    end;

    procedure SignData(DataInStream: InStream; HashAlgorithm: Enum "Hash Algorithm"; SignatureOutStream: OutStream)
    var
        Bytes: DotNet Array;
        Signature: DotNet Array;
    begin
        if DataInStream.EOS() then
            exit;
        InStreamToArray(DataInStream, Bytes);
        SignData(Bytes, HashAlgorithm, Signature);
        ArrayToOutStream(Signature, SignatureOutStream);
    end;

    local procedure SignData(Bytes: DotNet Array; HashAlgorithm: Enum "Hash Algorithm"; var Signature: DotNet Array)
    begin
        if Bytes.Length() = 0 then
            exit;
        TrySignData(Bytes, HashAlgorithm, Signature);
    end;

    [TryFunction]
    local procedure TrySignData(Bytes: DotNet Array; HashAlgorithm: Enum "Hash Algorithm"; var Signature: DotNet Array)
    begin
        Signature := DotNetRSACryptoServiceProvider.SignData(Bytes, Format(HashAlgorithm));
    end;
    #endregion

    #region VerifyData
    procedure VerifyData(XmlString: SecretText; DataInStream: InStream; HashAlgorithm: Enum "Hash Algorithm"; SignatureInStream: InStream): Boolean
    begin
        FromSecretXmlString(XmlString);
        exit(VerifyData(DataInStream, HashAlgorithm, SignatureInStream));
    end;

    procedure VerifyData(DataInStream: InStream; HashAlgorithm: Enum "Hash Algorithm"; SignatureInStream: InStream): Boolean
    var
        Bytes: DotNet Array;
        Signature: DotNet Array;
    begin
        if DataInStream.EOS() or SignatureInStream.EOS() then
            exit(false);
        InStreamToArray(DataInStream, Bytes);
        InStreamToArray(SignatureInStream, Signature);
        exit(VerifyData(Bytes, HashAlgorithm, Signature));
    end;

    local procedure VerifyData(Bytes: DotNet Array; HashAlgorithm: Enum "Hash Algorithm"; Signature: DotNet Array): Boolean
    var
        Verified: Boolean;
    begin
        if Bytes.Length() = 0 then
            exit(false);
        Verified := TryVerifyData(Bytes, HashAlgorithm, Signature);
        if not Verified and (GetLastErrorText() <> '') then
            Error(GetLastErrorText());
        exit(Verified);
    end;

    [TryFunction]
    local procedure TryVerifyData(Bytes: DotNet Array; HashAlgorithm: Enum "Hash Algorithm"; Signature: DotNet Array)
    begin
        if not DotNetRSACryptoServiceProvider.VerifyData(Bytes, Format(HashAlgorithm), Signature) then
            Error('');
    end;
    #endregion

    #region Encryption & Decryption
    [NonDebuggable]
    procedure Encrypt(XmlString: SecretText; PlainTextInStream: InStream; OaepPadding: Boolean; EncryptedTextOutStream: OutStream)
    var
        PlainTextBytes: DotNet Array;
        EncryptedTextBytes: DotNet Array;
    begin
        FromSecretXmlString(XmlString);
        InStreamToArray(PlainTextInStream, PlainTextBytes);
        EncryptedTextBytes := DotNetRSACryptoServiceProvider.Encrypt(PlainTextBytes, OaepPadding);
        ArrayToOutStream(EncryptedTextBytes, EncryptedTextOutStream);
    end;

    [NonDebuggable]
    procedure Decrypt(XmlString: SecretText; EncryptedTextInStream: InStream; OaepPadding: Boolean; DecryptedTextOutStream: OutStream)
    var
        EncryptedTextBytes: DotNet Array;
        DecryptedTextBytes: DotNet Array;
    begin
        FromSecretXmlString(XmlString);
        InStreamToArray(EncryptedTextInStream, EncryptedTextBytes);
        DecryptedTextBytes := DotNetRSACryptoServiceProvider.Decrypt(EncryptedTextBytes, OaepPadding);
        ArrayToOutStream(DecryptedTextBytes, DecryptedTextOutStream);
    end;
    #endregion

    #region XmlString
#if not CLEAN24
    [NonDebuggable]
    [Obsolete('Replaced by ToSecretXmlString with SecretText data type for XmlString.', '24.0')]
    procedure ToXmlString(IncludePrivateParameters: Boolean): Text
    begin
        exit(DotNetRSACryptoServiceProvider.ToXmlString(IncludePrivateParameters));
    end;

    [NonDebuggable]
    [Obsolete('Replaced by FromSecretXmlString with SecretText data type for XmlString.', '24.0')]
    procedure FromXmlString(XmlString: Text)
    begin
        RSACryptoServiceProvider();
        DotNetRSACryptoServiceProvider.FromXmlString(XmlString);
    end;
#endif
    procedure PublicKeyToXmlString(): Text
    begin
        exit(DotNetRSACryptoServiceProvider.ToXmlString(false));
    end;

    procedure ToSecretXmlString(IncludePrivateParameters: Boolean): SecretText
    begin
        exit(DotNetRSACryptoServiceProvider.ToXmlString(IncludePrivateParameters));
    end;

    [NonDebuggable]
    procedure FromSecretXmlString(XmlString: SecretText)
    begin
        RSACryptoServiceProvider();
        DotNetRSACryptoServiceProvider.FromXmlString(XmlString.Unwrap());
    end;
    #endregion

    local procedure RSACryptoServiceProvider()
    begin
        DotNetRSACryptoServiceProvider := DotNetRSACryptoServiceProvider.RSACryptoServiceProvider();
    end;

    local procedure ArrayToOutStream(Bytes: DotNet Array; OutputOutStream: OutStream)
    var
        DotNetMemoryStream: DotNet MemoryStream;
    begin
        DotNetMemoryStream := DotNetMemoryStream.MemoryStream(Bytes);
        CopyStream(OutputOutStream, DotNetMemoryStream);
    end;

    local procedure InStreamToArray(InputInStream: InStream; var Bytes: DotNet Array)
    var
        DotNetMemoryStream: DotNet MemoryStream;
    begin
        DotNetMemoryStream := DotNetMemoryStream.MemoryStream();
        CopyStream(DotNetMemoryStream, InputInStream);
        Bytes := DotNetMemoryStream.ToArray();
    end;
}