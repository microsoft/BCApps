// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Security.Encryption;

using System;

#if not CLEAN24
#pragma warning disable AL0432
codeunit 1448 "DSACryptoServiceProvider Impl." implements SignatureAlgorithm, "Signature Algorithm v2"
#pragma warning restore AL0432
#else
codeunit 1448 "DSACryptoServiceProvider Impl." implements "Signature Algorithm v2"
#endif
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        [NonDebuggable]
        DotNetDSACryptoServiceProvider: DotNet DSACryptoServiceProvider;

    [NonDebuggable]
    procedure GetInstance(var DotNetAsymmetricAlgorithm: DotNet AsymmetricAlgorithm)
    begin
        DotNetAsymmetricAlgorithm := DotNetDSACryptoServiceProvider;
    end;

    #region SignData
    [NonDebuggable]
    procedure SignData(XmlString: SecretText; DataInStream: InStream; HashAlgorithm: Enum "Hash Algorithm"; SignatureOutStream: OutStream)
    begin
        FromXmlString(XmlString.Unwrap());
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
    var
        DotNetHashAlgorithmName: DotNet HashAlgorithmName;
    begin
        DotNetHashAlgorithmName := DotNetHashAlgorithmName.HashAlgorithmName(Format(HashAlgorithm));
        Signature := DotNetDSACryptoServiceProvider.SignData(Bytes, DotNetHashAlgorithmName);
    end;
    #endregion

    #region VerifyData
    [NonDebuggable]
    procedure VerifyData(XmlString: SecretText; DataInStream: InStream; HashAlgorithm: Enum "Hash Algorithm"; SignatureInStream: InStream): Boolean
    begin
        FromXmlString(XmlString.Unwrap());
        VerifyData(DataInStream, HashAlgorithm, SignatureInStream);
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
    var
        DotNetHashAlgorithmName: DotNet HashAlgorithmName;
    begin
        DotNetHashAlgorithmName := DotNetHashAlgorithmName.HashAlgorithmName(Format(HashAlgorithm));
        if not DotNetDSACryptoServiceProvider.VerifyData(Bytes, Signature, DotNetHashAlgorithmName) then
            Error('');
    end;
    #endregion

    #region XmlString
    procedure FromXmlString(XmlString: Text)
    begin
        DSACryptoServiceProvider();
        DotNetDSACryptoServiceProvider.FromXmlString(XmlString);
    end;

    procedure ToXmlString(IncludePrivateParameters: Boolean): Text
    begin
        exit(DotNetDSACryptoServiceProvider.ToXmlString(IncludePrivateParameters));
    end;

    [NonDebuggable]
    procedure FromSecretXmlString(XmlString: SecretText)
    begin
        DSACryptoServiceProvider();
        DotNetDSACryptoServiceProvider.FromXmlString(XmlString.Unwrap());
    end;

    procedure ToSecretXmlString(IncludePrivateParameters: Boolean): SecretText
    begin
        exit(DotNetDSACryptoServiceProvider.ToXmlString(IncludePrivateParameters));
    end;
    #endregion

    [NonDebuggable]
    local procedure DSACryptoServiceProvider()
    begin
        DotNetDSACryptoServiceProvider := DotNetDSACryptoServiceProvider.DSACryptoServiceProvider();
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