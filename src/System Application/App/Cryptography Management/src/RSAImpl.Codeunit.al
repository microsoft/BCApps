namespace System.Security.Encryption;

using System;
#if not CLEAN24
#pragma warning disable AL0432
codeunit 1476 "RSA Impl." implements SignatureAlgorithm, "Signature Algorithm v2"
#pragma warning restore AL0432
#else
codeunit 1476 "RSA Impl." implements "Signature Algorithm v2"
#endif
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        DotNetRSA: DotNet RSA;

    procedure InitializeRSA(KeySize: Integer)
    begin
        DotNetRSA := DotNetRSA.Create(KeySize);
    end;

    procedure GetInstance(var DotNetAsymmetricAlgorithm: DotNet AsymmetricAlgorithm)
    begin
        DotNetAsymmetricAlgorithm := DotNetRSA;
    end;

    #region SignData
    procedure SignData(XmlString: SecretText; DataInStream: InStream; HashAlgorithm: Enum "Hash Algorithm"; SignatureOutStream: OutStream)
    begin
        FromSecretXmlString(XmlString);
        SignData(DataInStream, HashAlgorithm, Enum::"RSA Signature Padding"::Pss, SignatureOutStream);
    end;

    procedure SignData(XmlString: SecretText; DataInStream: InStream; HashAlgorithm: Enum "Hash Algorithm"; RSASignaturePadding: Enum "RSA Signature Padding"; SignatureOutStream: OutStream)
    begin
        FromSecretXmlString(XmlString);
        SignData(DataInStream, HashAlgorithm, RSASignaturePadding, SignatureOutStream);
    end;

    procedure SignData(DataInStream: InStream; HashAlgorithm: Enum "Hash Algorithm"; SignatureOutStream: OutStream)
    begin
        SignData(DataInStream, HashAlgorithm, Enum::"RSA Signature Padding"::Pss, SignatureOutStream);
    end;

    procedure SignData(DataInStream: InStream; HashAlgorithm: Enum "Hash Algorithm"; RSASignaturePadding: Enum "RSA Signature Padding"; SignatureOutStream: OutStream)
    var
        Bytes: DotNet Array;
        Signature: DotNet Array;
    begin
        if DataInStream.EOS() then
            exit;
        InStreamToArray(DataInStream, Bytes);
        SignData(Bytes, HashAlgorithm, RSASignaturePadding, Signature);
        ArrayToOutStream(Signature, SignatureOutStream);
    end;

    local procedure SignData(Bytes: DotNet Array; HashAlgorithm: Enum "Hash Algorithm"; RSASignaturePadding: Enum "RSA Signature Padding"; var Signature: DotNet Array)
    begin
        if Bytes.Length() = 0 then
            exit;
        TrySignData(Bytes, HashAlgorithm, RSASignaturePadding, Signature);
    end;

    [TryFunction]
    local procedure TrySignData(Bytes: DotNet Array; HashAlgorithm: Enum "Hash Algorithm"; RSASignaturePadding: Enum "RSA Signature Padding"; var Signature: DotNet Array)
    var
        DotNetHashAlgorithmName: DotNet HashAlgorithmName;
        DotNetRSASignaturePadding: DotNet RSASignaturePadding;
    begin
        HashAlgorithmEnumToDotNet(HashAlgorithm, DotNetHashAlgorithmName);
        RSASignaturePaddingToDotNet(RSASignaturePadding, DotNetRSASignaturePadding);
        Signature := DotNetRSA.SignData(Bytes, DotNetHashAlgorithmName, DotNetRSASignaturePadding);
    end;
    #endregion

    #region VerifyData
    procedure VerifyData(XmlString: SecretText; DataInStream: InStream; HashAlgorithm: Enum "Hash Algorithm"; SignatureInStream: InStream): Boolean
    begin
        FromSecretXmlString(XmlString);
        exit(VerifyData(DataInStream, HashAlgorithm, Enum::"RSA Signature Padding"::Pss, SignatureInStream));
    end;

    procedure VerifyData(XmlString: SecretText; DataInStream: InStream; HashAlgorithm: Enum "Hash Algorithm"; RSASignaturePadding: Enum "RSA Signature Padding"; SignatureInStream: InStream): Boolean
    begin
        FromSecretXmlString(XmlString);
        exit(VerifyData(DataInStream, HashAlgorithm, RSASignaturePadding, SignatureInStream));
    end;

    procedure VerifyData(DataInStream: InStream; HashAlgorithm: Enum "Hash Algorithm"; SignatureInStream: InStream): Boolean
    begin
        VerifyData(DataInStream, HashAlgorithm, Enum::"RSA Signature Padding"::Pss, SignatureInStream);
    end;

    procedure VerifyData(DataInStream: InStream; HashAlgorithm: Enum "Hash Algorithm"; RSASignaturePadding: Enum "RSA Signature Padding"; SignatureInStream: InStream): Boolean
    var
        Bytes: DotNet Array;
        Signature: DotNet Array;
    begin
        if DataInStream.EOS() or SignatureInStream.EOS() then
            exit(false);
        InStreamToArray(DataInStream, Bytes);
        InStreamToArray(SignatureInStream, Signature);
        exit(VerifyData(Bytes, HashAlgorithm, RSASignaturePadding, Signature));
    end;

    local procedure VerifyData(Bytes: DotNet Array; HashAlgorithm: Enum "Hash Algorithm"; RSASignaturePadding: Enum "RSA Signature Padding"; Signature: DotNet Array): Boolean
    var
        Verified: Boolean;
    begin
        if Bytes.Length() = 0 then
            exit(false);
        Verified := TryVerifyData(Bytes, HashAlgorithm, RSASignaturePadding, Signature);
        if not Verified and (GetLastErrorText() <> '') then
            Error(GetLastErrorText());
        exit(Verified);
    end;

    [TryFunction]
    local procedure TryVerifyData(Bytes: DotNet Array; HashAlgorithm: Enum "Hash Algorithm"; RSASignaturePadding: Enum "RSA Signature Padding"; Signature: DotNet Array)
    var
        DotNetHashAlgorithmName: DotNet HashAlgorithmName;
        DotNetRSASignaturePadding: DotNet RSASignaturePadding;
    begin
        HashAlgorithmEnumToDotNet(HashAlgorithm, DotNetHashAlgorithmName);
        RSASignaturePaddingToDotNet(RSASignaturePadding, DotNetRSASignaturePadding);
        if not DotNetRSA.VerifyData(Bytes, Signature, DotNetHashAlgorithmName, DotNetRSASignaturePadding) then
            Error('');
    end;
    #endregion

    #region Encryption & Decryption
    [NonDebuggable]
    procedure Encrypt(XmlString: SecretText; PlainTextInStream: InStream; OaepPadding: Boolean; EncryptedTextOutStream: OutStream)
    var
        PlainTextBytes: DotNet Array;
        EncryptedTextBytes: DotNet Array;
        DotNetRSAEncryptionPadding: DotNet RSAEncryptionPadding;
    begin
        FromSecretXmlString(XmlString);
        InStreamToArray(PlainTextInStream, PlainTextBytes);

        if OaepPadding then
            DotNetRSAEncryptionPadding := DotNetRSAEncryptionPadding.OaepSHA256
        else
            DotNetRSAEncryptionPadding := DotNetRSAEncryptionPadding.Pkcs1;

        EncryptedTextBytes := DotNetRSA.Encrypt(PlainTextBytes, DotNetRSAEncryptionPadding);
        ArrayToOutStream(EncryptedTextBytes, EncryptedTextOutStream);
    end;

    [NonDebuggable]
    procedure Decrypt(XmlString: SecretText; EncryptedTextInStream: InStream; OaepPadding: Boolean; DecryptedTextOutStream: OutStream)
    var
        EncryptedTextBytes: DotNet Array;
        DecryptedTextBytes: DotNet Array;
        DotNetRSAEncryptionPadding: DotNet RSAEncryptionPadding;
    begin
        FromSecretXmlString(XmlString);
        InStreamToArray(EncryptedTextInStream, EncryptedTextBytes);
        if OaepPadding then
            DotNetRSAEncryptionPadding := DotNetRSAEncryptionPadding.OaepSHA256
        else
            DotNetRSAEncryptionPadding := DotNetRSAEncryptionPadding.Pkcs1;
        DecryptedTextBytes := DotNetRSA.Decrypt(EncryptedTextBytes, DotNetRSAEncryptionPadding);
        ArrayToOutStream(DecryptedTextBytes, DecryptedTextOutStream);
    end;
    #endregion


    #region XmlString
#if not CLEAN24
    [NonDebuggable]
    [Obsolete('Replaced by ToSecretXmlString with SecretText data type for XmlString.', '25.0')]
    procedure ToXmlString(IncludePrivateParameters: Boolean): Text
    begin
        exit(DotNetRSA.ToXmlString(IncludePrivateParameters));
    end;

    [NonDebuggable]
    [Obsolete('Replaced by FromSecretXmlString with SecretText data type for XmlString.', '25.0')]
    procedure FromXmlString(XmlString: Text)
    begin
        RSA();
        DotNetRSA.FromXmlString(XmlString);
    end;
#endif
    procedure ToSecretXmlString(IncludePrivateParameters: Boolean): SecretText
    begin
        exit(DotNetRSA.ToXmlString(IncludePrivateParameters));
    end;

    [NonDebuggable]
    procedure FromSecretXmlString(XmlString: SecretText)
    begin
        RSA();
        DotNetRSA.FromXmlString(XmlString.Unwrap());
    end;
    #endregion

    local procedure RSA()
    begin
        DotNetRSA := DotNetRSA.Create(2048);
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

    local procedure HashAlgorithmEnumToDotNet(HashAlgorithm: Enum "Hash Algorithm"; var DotNetHashAlgorithmName: DotNet HashAlgorithmName)
    begin
        case
           HashAlgorithm of
            HashAlgorithm::MD5:
                DotNetHashAlgorithmName := DotNetHashAlgorithmName.MD5;
            HashAlgorithm::SHA1:
                DotNetHashAlgorithmName := DotNetHashAlgorithmName.SHA1;
            HashAlgorithm::SHA256:
                DotNetHashAlgorithmName := DotNetHashAlgorithmName.SHA256;
            HashAlgorithm::SHA384:
                DotNetHashAlgorithmName := DotNetHashAlgorithmName.SHA384;
            HashAlgorithm::SHA512:
                DotNetHashAlgorithmName := DotNetHashAlgorithmName.SHA512;
        end;
    end;

    local procedure RSASignaturePaddingToDotNet(RSASignaturePadding: Enum "RSA Signature Padding"; var DotNetRSASignaturePadding: DotNet RSASignaturePadding)
    begin
        case RSASignaturePadding of
            RSASignaturePadding::Pkcs1:
                DotNetRSASignaturePadding := DotNetRSASignaturePadding.Pkcs1;
            RSASignaturePadding::Pss:
                DotNetRSASignaturePadding := DotNetRSASignaturePadding.Pss;
        end;
    end;
}