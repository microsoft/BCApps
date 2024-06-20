// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Security.Encryption;

using System;
using System.Security.AccessControl;
using System.Utilities;

codeunit 1279 "Cryptography Management Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        CryptographyManagement: Codeunit "Cryptography Management";
        RijndaelProvider: DotNet "Cryptography.RijndaelManaged";
        CryptoStreamMode: DotNet "Cryptography.CryptoStreamMode";
        ExportEncryptionKeyFileDialogTxt: Label 'Choose the location where you want to save the encryption key.';
        ExportEncryptionKeyConfirmQst: Label 'The encryption key file must be protected by a password and stored in a safe location.\\Do you want to save the encryption key?';
        FileImportCaptionMsg: Label 'Select a key file to import.';
        DefaultEncryptionKeyFileNameTxt: Label 'EncryptionKey.key';
        KeyFileFilterTxt: Label 'Key File(*.key)|*.key';
        ReencryptConfirmQst: Label 'The encryption is already enabled. Continuing will decrypt the encrypted data and encrypt it again with the new key.\\Do you want to continue?';
        EncryptionKeyImportedMsg: Label 'The key was imported successfully.';
        EnableEncryptionConfirmQst: Label 'Enabling encryption will generate an encryption key on the server.\It is recommended that you save a copy of the encryption key in a safe location.\\Do you want to continue?';
        DisableEncryptionConfirmQst: Label 'Disabling encryption will decrypt the encrypted data and store it in the database in an unsecure way.\\Do you want to continue?';
        EncryptionCheckFailErr: Label 'Encryption is either not enabled or the encryption key cannot be found.';
        EncryptionIsNotActivatedQst: Label 'Data encryption is not activated. It is recommended that you encrypt data. \Do you want to open the Data Encryption Management window?';

    procedure Encrypt(InputString: Text[215]): Text
    begin
        AssertEncryptionPossible();
        if InputString = '' then
            exit('');
        exit(System.Encrypt(InputString));
    end;

    procedure Decrypt(EncryptedString: Text): Text
    begin
        AssertEncryptionPossible();
        if EncryptedString = '' then
            exit('');
        exit(System.Decrypt(EncryptedString))
    end;

    procedure ExportKey()
    var
        PasswordDialogManagement: Codeunit "Password Dialog Management";
        TempBlob: Codeunit "Temp Blob";
        Password: SecretText;
    begin
        AssertEncryptionPossible();
        if Confirm(ExportEncryptionKeyConfirmQst, true) then begin
            Password := PasswordDialogManagement.OpenSecretPasswordDialog();
            if Password.IsEmpty() then
                exit;
        end;

        GetEncryptionKeyAsStream(TempBlob, Password);
        DownloadEncryptionFileFromStream(TempBlob);
    end;

    procedure ExportKeyAsStream(var TempBlob: Codeunit "Temp Blob"; Password: SecretText)
    begin
        AssertEncryptionPossible();
        GetEncryptionKeyAsStream(TempBlob, Password);
    end;

    [NonDebuggable]
    local procedure GetEncryptionKeyAsStream(var TempBlob: Codeunit "Temp Blob"; Password: SecretText)
    var
        FileObj: File;
        FileInStream: InStream;
        TempOutStream: OutStream;
        ServerFilename: Text;
    begin
        ServerFilename := ExportEncryptionKey(Password.Unwrap());
        FileObj.Open(ServerFilename);

        TempBlob.CreateOutStream(TempOutStream);
        FileObj.CreateInStream(FileInStream);
        CopyStream(TempOutStream, FileInStream);

        FileObj.Close();
        File.Erase(ServerFilename);
    end;

    local procedure DownloadEncryptionFileFromStream(TempBlob: Codeunit "Temp Blob")
    var
        InStreamObj: InStream;
        FileName: Text;
    begin
        TempBlob.CreateInStream(InStreamObj);
        FileName := DefaultEncryptionKeyFileNameTxt;

        if not DownloadFromStream(InStreamObj, ExportEncryptionKeyFileDialogTxt, '', KeyFileFilterTxt, FileName) then
            if GetLastErrorText() <> '' then
                Error('%1', GetLastErrorText());
    end;

    procedure ImportKey()
    var
        PasswordDialogManagement: Codeunit "Password Dialog Management";
        TempKeyFilePath: Text;
        Password: SecretText;
    begin
        TempKeyFilePath := UploadFile();

        // TempKeyFilePath is '' if the user cancelled the Upload file dialog.
        if TempKeyFilePath = '' then
            exit;

        Password := PasswordDialogManagement.OpenSecretPasswordDialog(true, true);
        if not Password.IsEmpty() then
            ImportKeyAndConfirm(TempKeyFilePath, Password);

        File.Erase(TempKeyFilePath);
    end;

    procedure ChangeKey()
    var
        PasswordDialogManagement: Codeunit "Password Dialog Management";
        TempKeyFilePath: Text;
        Password: SecretText;
    begin
        TempKeyFilePath := UploadFile();

        // TempKeyFilePath is '' if the user cancelled the Upload file dialog.
        if TempKeyFilePath = '' then
            exit;

        Password := PasswordDialogManagement.OpenSecretPasswordDialog(true, true);
        if not Password.IsEmpty() then begin
            if IsEncryptionEnabled() then begin
                if not Confirm(ReencryptConfirmQst, true) then
                    exit;
                DisableEncryption(true);
            end;

            ImportKeyAndConfirm(TempKeyFilePath, Password);
        end;

        File.Erase(TempKeyFilePath);
    end;

    procedure EnableEncryption(Silent: Boolean)
    var
        PasswordDialogManagement: Codeunit "Password Dialog Management";
        TempBlob: Codeunit "Temp Blob";
        ShouldExportKey: Boolean;
        Password: SecretText;
    begin
        if Silent then begin
            CreateEncryptionKeys();
            exit;
        end;

        if Confirm(EnableEncryptionConfirmQst, true) then begin
            if Confirm(ExportEncryptionKeyConfirmQst, true) then begin
                Password := PasswordDialogManagement.OpenSecretPasswordDialog();
                if not Password.IsEmpty() then
                    ShouldExportKey := true;
            end;

            CreateEncryptionKeys();
            if ShouldExportKey then begin
                GetEncryptionKeyAsStream(TempBlob, Password);
                DownloadEncryptionFileFromStream(TempBlob);
            end;
        end;
    end;

    local procedure CreateEncryptionKeys()
    begin
        // no user interaction on webservices
        CryptographyManagement.OnBeforeEnableEncryptionOnPrem();
        CreateEncryptionKey();
    end;

    procedure DisableEncryption(Silent: Boolean)
    begin
        // Silent is FALSE when we want the user to take action on if the encryption should be disabled or not. In cases like import key
        // Silent should be TRUE as disabling encryption is a must before importing a new key, else data will be lost.
        if not Silent then
            if not Confirm(DisableEncryptionConfirmQst, true) then
                exit;

        CryptographyManagement.OnBeforeDisableEncryptionOnPrem();
        DeleteEncryptionKey();
    end;

    procedure IsEncryptionEnabled(): Boolean
    begin
        exit(EncryptionEnabled());
    end;

    procedure IsEncryptionPossible(): Boolean
    begin
        // ENCRYPTIONKEYEXISTS checks if the correct key is present, which only works if encryption is enabled
        exit(EncryptionKeyExists());
    end;

    local procedure AssertEncryptionPossible()
    begin
        if IsEncryptionEnabled() then
            if IsEncryptionPossible() then
                exit;

        Error(EncryptionCheckFailErr);
    end;

    local procedure UploadFile(): Text
    var
        ServerFileName: Text;
    begin
        Upload(FileImportCaptionMsg, '', KeyFileFilterTxt, DefaultEncryptionKeyFileNameTxt, ServerFileName);
        exit(ServerFileName);
    end;

    [NonDebuggable]
    local procedure ImportKeyAndConfirm(KeyFilePath: Text; Password: SecretText)
    begin
        ImportEncryptionKey(KeyFilePath, Password.Unwrap());
        Message(EncryptionKeyImportedMsg);
    end;

    procedure GetEncryptionIsNotActivatedQst(): Text
    begin
        exit(EncryptionIsNotActivatedQst);
    end;

    procedure GenerateHash(InputString: Text; HashAlgorithmType: Option MD5,SHA1,SHA256,SHA384,SHA512): Text
    var
        HashBytes: DotNet Array;
    begin
        if not GenerateHashBytes(HashBytes, InputString, HashAlgorithmType) then
            exit('');
        exit(ConvertByteHashToString(HashBytes));
    end;

    procedure GenerateHashAsBase64String(InputString: Text; HashAlgorithmType: Option MD5,SHA1,SHA256,SHA384,SHA512): Text
    var
        HashBytes: DotNet Array;
    begin
        if not GenerateHashBytes(HashBytes, InputString, HashAlgorithmType) then
            exit('');
        exit(ConvertByteHashToBase64String(HashBytes));
    end;

    local procedure GenerateHashBytes(var HashBytes: DotNet Array; InputString: Text; HashAlgorithmType: Option MD5,SHA1,SHA256,SHA384,SHA512): Boolean
    var
        Encoding: DotNet Encoding;
    begin
        if not TryGenerateHash(HashBytes, Encoding.UTF8().GetBytes(InputString), Format(HashAlgorithmType)) then
            Error(GetLastErrorText());
        exit(true);
    end;

    [TryFunction]
    local procedure TryGenerateHash(var HashBytes: DotNet Array; Bytes: DotNet Array; Algorithm: Text)
    var
        HashAlgorithm: DotNet HashAlgorithm;
    begin
        HashAlgorithm := HashAlgorithm.Create(Algorithm);
        HashBytes := HashAlgorithm.ComputeHash(Bytes);
        HashAlgorithm.Dispose();
    end;

    [NonDebuggable]
    procedure GenerateHash(InputString: Text; "Key": SecretText; HashAlgorithmType: Option HMACMD5,HMACSHA1,HMACSHA256,HMACSHA384,HMACSHA512): Text
    var
        HashBytes: DotNet Array;
        Encoding: DotNet Encoding;
    begin
        if not GenerateKeyedHashBytes(HashBytes, InputString, Encoding.UTF8().GetBytes(Key.Unwrap()), HashAlgorithmType) then
            exit('');
        exit(ConvertByteHashToString(HashBytes));
    end;

    [NonDebuggable]
    procedure GenerateHashAsBase64String(InputString: Text; "Key": SecretText; HashAlgorithmType: Option HMACMD5,HMACSHA1,HMACSHA256,HMACSHA384,HMACSHA512): Text
    var
        HashBytes: DotNet Array;
        Encoding: DotNet Encoding;
    begin
        if not GenerateKeyedHashBytes(HashBytes, InputString, Encoding.UTF8().GetBytes(Key.Unwrap()), HashAlgorithmType) then
            exit('');
        exit(ConvertByteHashToBase64String(HashBytes));
    end;

    [NonDebuggable]
    procedure GenerateBase64KeyedHashAsBase64String(InputString: Text; "Key": SecretText; HashAlgorithmType: Option HMACMD5,HMACSHA1,HMACSHA256,HMACSHA384,HMACSHA512): Text
    var
        HashBytes: DotNet Array;
        Convert: DotNet Convert;
    begin
        if not GenerateKeyedHashBytes(HashBytes, InputString, Convert.FromBase64String(Key.Unwrap()), HashAlgorithmType) then
            exit('');
        exit(ConvertByteHashToBase64String(HashBytes));
    end;

    local procedure GenerateKeyedHashBytes(var HashBytes: DotNet Array; InputString: Text; "Key": DotNet Array; HashAlgorithmType: Option HMACMD5,HMACSHA1,HMACSHA256,HMACSHA384,HMACSHA512): Boolean
    begin
        if (InputString = '') or (Key.Length() = 0) then
            exit(false);
        if not TryGenerateKeyedHash(HashBytes, InputString, Key, Format(HashAlgorithmType)) then
            Error(GetLastErrorText());
        exit(true);
    end;

    [TryFunction]
    local procedure TryGenerateKeyedHash(var HashBytes: DotNet Array; InputString: Text; "Key": DotNet Array; Algorithm: Text)
    var
        KeyedHashAlgorithm: DotNet KeyedHashAlgorithm;
        Encoding: DotNet Encoding;
    begin
        KeyedHashAlgorithm := KeyedHashAlgorithm.Create(Algorithm);
        KeyedHashAlgorithm.Key(Key);
        HashBytes := KeyedHashAlgorithm.ComputeHash(Encoding.UTF8().GetBytes(InputString));
        KeyedHashAlgorithm.Dispose();
    end;

    local procedure ConvertByteHashToString(HashBytes: DotNet Array): Text
    var
        Byte: DotNet Byte;
        StringBuilder: DotNet StringBuilder;
        I: Integer;
    begin
        StringBuilder := StringBuilder.StringBuilder();
        for I := 0 to HashBytes.Length() - 1 do begin
            Byte := HashBytes.GetValue(I);
            StringBuilder.Append(Byte.ToString('X2'));
        end;
        exit(StringBuilder.ToString());
    end;

    local procedure ConvertByteHashToBase64String(HashBytes: DotNet Array): Text
    var
        Convert: DotNet Convert;
    begin
        exit(Convert.ToBase64String(HashBytes));
    end;

    procedure GenerateHash(DataInStream: InStream; HashAlgorithmType: Option MD5,SHA1,SHA256,SHA384,SHA512): Text
    var
        MemoryStream: DotNet MemoryStream;
        HashBytes: DotNet Array;
    begin
        if DataInStream.EOS() then
            exit('');
        MemoryStream := MemoryStream.MemoryStream();
        CopyStream(MemoryStream, DataInStream);
        if not TryGenerateHash(HashBytes, MemoryStream.ToArray(), Format(HashAlgorithmType)) then
            Error(GetLastErrorText());
        exit(ConvertByteHashToString(HashBytes));
    end;

    [NonDebuggable]
    procedure GenerateBase64KeyedHash(InputString: Text; "Key": SecretText; HashAlgorithmType: Option HMACMD5,HMACSHA1,HMACSHA256,HMACSHA384,HMACSHA512): Text
    var
        HashBytes: DotNet Array;
        Convert: DotNet Convert;
    begin
        if not GenerateKeyedHashBytes(HashBytes, InputString, Convert.FromBase64String(Key.Unwrap()), HashAlgorithmType) then
            exit('');
        exit(ConvertByteHashToString(HashBytes));
    end;

    procedure SignData(InputString: Text; XmlString: SecretText; HashAlgorithm: Enum "Hash Algorithm"; SignatureOutStream: OutStream)
    var
        TempBlob: Codeunit "Temp Blob";
        DataOutStream: OutStream;
        DataInStream: InStream;
    begin
        if InputString = '' then
            exit;
        TempBlob.CreateOutStream(DataOutStream, TextEncoding::UTF8);
        TempBlob.CreateInStream(DataInStream, TextEncoding::UTF8);
        DataOutStream.WriteText(InputString);
        SignData(DataInStream, XmlString, HashAlgorithm, SignatureOutStream);
    end;

    procedure SignData(InputString: Text; SignatureKey: Codeunit "Signature Key"; HashAlgorithm: Enum "Hash Algorithm"; SignatureOutStream: OutStream)
    begin
        SignData(InputString, SignatureKey.ToXmlString(), HashAlgorithm, SignatureOutStream);
    end;

    [NonDebuggable]
    procedure SignData(DataInStream: InStream; XmlString: SecretText; HashAlgorithm: Enum "Hash Algorithm"; SignatureOutStream: OutStream)
    var
        ISignatureAlgorithm: Interface "Signature Algorithm v2";
    begin
        if DataInStream.EOS() then
            exit;
        ISignatureAlgorithm := Enum::SignatureAlgorithm::RSA;
        ISignatureAlgorithm.FromSecretXmlString(XmlString);
        ISignatureAlgorithm.SignData(DataInStream, HashAlgorithm, SignatureOutStream);
    end;

    procedure SignData(DataInStream: InStream; SignatureKey: Codeunit "Signature Key"; HashAlgorithm: Enum "Hash Algorithm"; SignatureOutStream: OutStream)
    begin
        SignData(DataInStream, SignatureKey.ToXmlString(), HashAlgorithm, SignatureOutStream);
    end;

    procedure SignData(InputString: Text; XmlString: SecretText; HashAlgorithm: Enum "Hash Algorithm"; RSASignaturePadding: Enum "RSA Signature Padding"; SignatureOutStream: OutStream)
    var
        TempBlob: Codeunit "Temp Blob";
        DataOutStream: OutStream;
        DataInStream: InStream;
    begin
        if InputString = '' then
            exit;
        TempBlob.CreateOutStream(DataOutStream, TextEncoding::UTF8);
        TempBlob.CreateInStream(DataInStream, TextEncoding::UTF8);
        DataOutStream.WriteText(InputString);
        SignData(DataInStream, XmlString, HashAlgorithm, SignatureOutStream);
    end;

    procedure SignData(DataInStream: InStream; XmlString: SecretText; HashAlgorithm: Enum "Hash Algorithm"; RSASignaturePadding: Enum "RSA Signature Padding"; SignatureOutStream: OutStream)
    var
        RSAImpl: Codeunit "RSA Impl.";
    begin
        if DataInStream.EOS() then
            exit;

        RSAImpl.SignData(XmlString, DataInStream, HashAlgorithm, RSASignaturePadding, SignatureOutStream);
    end;

    procedure VerifyData(InputString: Text; XmlString: SecretText; HashAlgorithm: Enum "Hash Algorithm"; SignatureInStream: InStream): Boolean
    var
        TempBlob: Codeunit "Temp Blob";
        DataOutStream: OutStream;
        DataInStream: InStream;
    begin
        if InputString = '' then
            exit(false);
        TempBlob.CreateOutStream(DataOutStream, TextEncoding::UTF8);
        TempBlob.CreateInStream(DataInStream, TextEncoding::UTF8);
        DataOutStream.WriteText(InputString);
        exit(VerifyData(DataInStream, XmlString, HashAlgorithm, SignatureInStream));
    end;

    procedure VerifyData(InputString: Text; SignatureKey: Codeunit "Signature Key"; HashAlgorithm: Enum "Hash Algorithm"; SignatureInStream: InStream): Boolean
    begin
        exit(VerifyData(InputString, SignatureKey.ToXmlString(), HashAlgorithm, SignatureInStream));
    end;

    [NonDebuggable]
    procedure VerifyData(DataInStream: InStream; XmlString: SecretText; HashAlgorithm: Enum "Hash Algorithm"; SignatureInStream: InStream): Boolean
    var
        ISignatureAlgorithm: Interface "Signature Algorithm v2";
    begin
        if DataInStream.EOS() then
            exit(false);
        ISignatureAlgorithm := Enum::SignatureAlgorithm::RSA;
        ISignatureAlgorithm.FromSecretXmlString(XmlString);
        exit(ISignatureAlgorithm.VerifyData(DataInStream, HashAlgorithm, SignatureInStream));
    end;

    procedure VerifyData(DataInStream: InStream; SignatureKey: Codeunit "Signature Key"; HashAlgorithm: Enum "Hash Algorithm"; SignatureInStream: InStream): Boolean
    begin
        exit(VerifyData(DataInStream, SignatureKey.ToXmlString(), HashAlgorithm, SignatureInStream));
    end;

    procedure InitRijndaelProvider()
    begin
        RijndaelProvider := RijndaelProvider.RijndaelManaged();
        RijndaelProvider.GenerateKey();
        RijndaelProvider.GenerateIV();
    end;

    [NonDebuggable]
    procedure InitRijndaelProvider(EncryptionKey: SecretText)
    var
        Encoding: DotNet Encoding;
    begin
        InitRijndaelProvider();
        RijndaelProvider."Key" := Encoding.GetEncoding(0).GetBytes(EncryptionKey.Unwrap());
    end;

    procedure InitRijndaelProvider(EncryptionKey: SecretText; BlockSize: Integer)
    begin
        InitRijndaelProvider(EncryptionKey);
        SetBlockSize(BlockSize);
    end;

    procedure InitRijndaelProvider(EncryptionKey: SecretText; BlockSize: Integer; CipherMode: Text)
    begin
        InitRijndaelProvider(EncryptionKey, BlockSize);
        SetCipherMode(CipherMode);
    end;

    procedure InitRijndaelProvider(EncryptionKey: SecretText; BlockSize: Integer; CipherMode: Text; PaddingMode: Text)
    begin
        InitRijndaelProvider(EncryptionKey, BlockSize, CipherMode);
        SetPaddingMode(PaddingMode);
    end;

    procedure SetBlockSize(BlockSize: Integer)
    begin
        Construct();
        RijndaelProvider.BlockSize := BlockSize;
    end;

    procedure SetCipherMode(CipherMode: Text)
    var
        CryptographyCipherMode: DotNet "Cryptography.CipherMode";
    begin
        Construct();
        CryptographyCipherMode := RijndaelProvider.Mode();
        RijndaelProvider.Mode := CryptographyCipherMode.Parse(CryptographyCipherMode.GetType(), CipherMode);
    end;

    procedure SetPaddingMode(PaddingMode: Text)
    var
        CryptographyPaddingMode: DotNet "Cryptography.PaddingMode";
    begin
        Construct();
        CryptographyPaddingMode := RijndaelProvider.Padding();
        RijndaelProvider.Padding := CryptographyPaddingMode.Parse(CryptographyPaddingMode.GetType(), PaddingMode);
    end;

    [NonDebuggable]
    procedure SetEncryptionData(KeyAsBase64: SecretText; VectorAsBase64: Text)
    var
        Convert: DotNet Convert;
    begin
        Construct();
        RijndaelProvider."Key"(Convert.FromBase64String(KeyAsBase64.Unwrap()));
        RijndaelProvider.IV(Convert.FromBase64String(VectorAsBase64));
    end;

    procedure IsValidKeySize(KeySize: Integer): Boolean
    begin
        Construct();
        exit(RijndaelProvider.ValidKeySize(KeySize))
    end;

    procedure GetLegalKeySizeValues(var MinSize: Integer; var MaxSize: Integer; var SkipSize: Integer)
    var
        KeySizesArray: DotNet "Cryptography.KeySizesArray";
        KeySizes: DotNet "Cryptography.KeySizes";
    begin
        Construct();
        KeySizesArray := RijndaelProvider.LegalKeySizes();
        KeySizes := KeySizesArray.GetValue(0);
        MinSize := KeySizes.MinSize();
        MaxSize := KeySizes.MaxSize();
        SkipSize := KeySizes.SkipSize();
    end;

    procedure GetLegalBlockSizeValues(var MinSize: Integer; var MaxSize: Integer; var SkipSize: Integer)
    var
        KeySizesArray: DotNet "Cryptography.KeySizesArray";
        KeySizes: DotNet "Cryptography.KeySizes";
    begin
        Construct();
        KeySizesArray := RijndaelProvider.LegalBlockSizes();
        KeySizes := KeySizesArray.GetValue(0);
        MinSize := KeySizes.MinSize();
        MaxSize := KeySizes.MaxSize();
        SkipSize := KeySizes.SkipSize();
    end;

    procedure GetEncryptionData(var KeyAsBase64: Text; var VectorAsBase64: Text)
    var
        Convert: DotNet Convert;
    begin
        Construct();
        KeyAsBase64 := Convert.ToBase64String(RijndaelProvider."Key"());
        VectorAsBase64 := Convert.ToBase64String(RijndaelProvider.IV());
    end;

    procedure GetEncryptionData(var KeyAsBase64: SecretText; var VectorAsBase64: Text)
    var
        Convert: DotNet Convert;
    begin
        Construct();
        KeyAsBase64 := Convert.ToBase64String(RijndaelProvider."Key"());
        VectorAsBase64 := Convert.ToBase64String(RijndaelProvider.IV());
    end;

    [NonDebuggable]
    procedure EncryptRijndael(PlainText: Text) EncryptedText: Text
    begin
        EncryptedText := EncryptRijndaelSecret(PlainText).Unwrap();
    end;

    [NonDebuggable]
    procedure EncryptRijndaelSecret(PlainText: SecretText) EncryptedText: SecretText
    var
        Encryptor: DotNet "Cryptography.ICryptoTransform";
        Convert: DotNet Convert;
        EncMemoryStream: DotNet MemoryStream;
        EncCryptoStream: DotNet "Cryptography.CryptoStream";
        EncStreamWriter: DotNet StreamWriter;
    begin
        Construct();
        Encryptor := RijndaelProvider.CreateEncryptor();
        EncMemoryStream := EncMemoryStream.MemoryStream();
        EncCryptoStream := EncCryptoStream.CryptoStream(EncMemoryStream, Encryptor, CryptoStreamMode.Write);
        EncStreamWriter := EncStreamWriter.StreamWriter(EncCryptoStream);
        EncStreamWriter.Write(PlainText.Unwrap());
        EncStreamWriter.Close();
        EncCryptoStream.Close();
        EncMemoryStream.Close();
        EncryptedText := Convert.ToBase64String(EncMemoryStream.ToArray());
    end;

    [NonDebuggable]
    procedure DecryptRijndael(EncryptedText: SecretText) PlainText: Text
    begin
        PlainText := DecryptRijndaelSecret(EncryptedText).Unwrap();
    end;

    [NonDebuggable]
    procedure DecryptRijndaelSecret(EncryptedText: SecretText) PlainText: SecretText
    var
        Decryptor: DotNet "Cryptography.ICryptoTransform";
        Convert: DotNet Convert;
        DecMemoryStream: DotNet MemoryStream;
        DecCryptoStream: DotNet "Cryptography.CryptoStream";
        DecStreamReader: DotNet StreamReader;
        NullChar: Char;
    begin
        Construct();
        Decryptor := RijndaelProvider.CreateDecryptor();
        DecMemoryStream := DecMemoryStream.MemoryStream(Convert.FromBase64String(EncryptedText.Unwrap()));
        DecCryptoStream := DecCryptoStream.CryptoStream(DecMemoryStream, Decryptor, CryptoStreamMode.Read);
        DecStreamReader := DecStreamReader.StreamReader(DecCryptoStream);
#pragma warning disable AA0205
        PlainText := DelChr(DecStreamReader.ReadToEnd(), '>', NullChar);
#pragma warning restore
        DecStreamReader.Close();
        DecCryptoStream.Close();
        DecMemoryStream.Close();
    end;

    local procedure Construct()
    begin
        if IsNull(RijndaelProvider) then
            InitRijndaelProvider();
    end;

    [NonDebuggable]
    procedure HashRfc2898DeriveBytes(InputString: Text; Salt: Text; NoOfBytes: Integer; HashAlgorithmType: Option MD5,SHA1,SHA256,SHA384,SHA512): Text;
    var
        ByteArray: DotNet Array;
        Convert: DotNet Convert;
        Encoding: DotNet Encoding;
        Rfc2898DeriveBytes: DotNet Rfc2898DeriveBytes;
    begin
        if Salt = '' then
            exit;

        //Implement password-based key derivation functionality, PBKDF2, by using a pseudo-random number generator based on HMACSHA1.
        Rfc2898DeriveBytes := Rfc2898DeriveBytes.Rfc2898DeriveBytes(InputString, Encoding.ASCII.GetBytes(Salt));

        //Return a Base64 encoded string of the hash of the first X bytes (X = NoOfBytes) returned from the generator.
        if not TryGenerateHash(ByteArray, Rfc2898DeriveBytes.GetBytes(NoOfBytes), Format(HashAlgorithmType)) then
            Error(GetLastErrorText());

        exit(Convert.ToBase64String(ByteArray));
    end;
}