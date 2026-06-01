// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Security.Encryption;

using System.Security.Encryption;
using System.TestLibraries.Utilities;
codeunit 132575 "Rijndael Cryptography Test"
{
    Subtype = Test;

    var
        LibraryAssert: Codeunit "Library Assert";
        LibraryAny: Codeunit "Any";

    [Test]
    procedure VerifyEncryptText()
    var
        RijndaelCryptography: Codeunit "Rijndael Cryptography";
        EncryptedText: Text;
    begin
        // [GIVEN] With Encryption Key 
        RijndaelCryptography.InitRijndaelProvider(GetECP128BitEncryptionKey(), 128, 'ECB', 'None');
        // [WHEN] Encrypt Text 
        EncryptedText := RijndaelCryptography.Encrypt(GetECP128BitPlainText());
        // [THEN] Verify Result 
        LibraryAssert.AreEqual(GetECP128BitCryptedText(), EncryptedText, 'Failed to encrypt text with ECB');
    end;

    [Test]
    procedure VerifyDecryptText()
    var
        RijndaelCryptography: Codeunit "Rijndael Cryptography";
        PlainText: Text;
    begin
        // [GIVEN] With Encryption Key 
        RijndaelCryptography.InitRijndaelProvider(GetECP128BitEncryptionKey(), 128, 'ECB', 'None');
        // [WHEN] Plain Text
        PlainText := RijndaelCryptography.Decrypt(GetECP128BitCryptedText());
        // [THEN] Verify Result 
        LibraryAssert.AreEqual(GetECP128BitPlainText(), PlainText, 'Failed to decrypt text with ECB');
    end;

    [Test]
    procedure VerifyEncryptAndDecryptText()
    var
        RijndaelCryptography: Codeunit "Rijndael Cryptography";
        PlainText: Text;
        ResultText: Text;
    begin
        // [GIVEN] Default Encryption         
        PlainText := LibraryAny.AlphanumericText(50);
        // [WHEN] Encrypt And Decrypt 
        ResultText := RijndaelCryptography.Decrypt(RijndaelCryptography.Encrypt(PlainText));
        // [THEN] Verify Result 
        LibraryAssert.AreEqual(PlainText, ResultText, 'Decrypting an encrypted text failed.');
    end;

    [Test]
    procedure VerifyMinimumKeySize()
    var
        RijndaelCryptography: Codeunit "Rijndael Cryptography";
        MinSize: Integer;
        MaxSize: Integer;
        SkipSize: Integer;
    begin
        // [GIVEN] Default Encryption
        RijndaelCryptography.InitRijndaelProvider();
        // [WHEN] Min Key Size Allowed 
        RijndaelCryptography.GetLegalKeySizeValues(MinSize, MaxSize, SkipSize);
        // [THEN] Expected to be valid
        LibraryAssert.IsTrue(RijndaelCryptography.IsValidKeySize(MinSize), 'Minimum Key Size failed to verify');
    end;

    [Test]
    procedure VerifyMaximumKeySize()
    var
        RijndaelCryptography: Codeunit "Rijndael Cryptography";
        MinSize: Integer;
        MaxSize: Integer;
        SkipSize: Integer;
    begin
        // [GIVEN] Default Encryption
        RijndaelCryptography.InitRijndaelProvider();
        // [WHEN] Min Key Size Allowed 
        RijndaelCryptography.GetLegalKeySizeValues(MinSize, MaxSize, SkipSize);
        // [THEN] Expected to be valid
        LibraryAssert.IsTrue(RijndaelCryptography.IsValidKeySize(MaxSize), 'Minimum Key Size failed to verify');
    end;

    [Test]
    procedure VerifyCreateEncryptionKeyAndDecryption()
    var
        RijndaelCryptography1: Codeunit "Rijndael Cryptography";
        RijndaelCryptography2: Codeunit "Rijndael Cryptography";
        KeyAsBase64: SecretText;
        VectorAsBase64: Text;
        PlainText: Text;
        CryptedText: Text;
    begin
        // [GIVEN] Default Encryption        
        RijndaelCryptography1.InitRijndaelProvider();
        PlainText := LibraryAny.AlphanumericText(50);

        // [WHEN] Get Created Encryption Data
        RijndaelCryptography1.GetEncryptionData(KeyAsBase64, VectorAsBase64);
        CryptedText := RijndaelCryptography1.Encrypt(PlainText);

        // [THEN] Validate Decryption With Generated Key
        RijndaelCryptography2.SetEncryptionData(KeyAsBase64, VectorAsBase64);
        LibraryAssert.AreEqual(PlainText, RijndaelCryptography2.Decrypt(CryptedText), 'Set Encryption Datay and Decrypt failed');
    end;

    [Test]
    procedure VerifyEncryptBinaryDataProducesExpectedResult()
    var
        RijndaelCryptography: Codeunit "Rijndael Cryptography";
        BinaryDataAsBase64: Text;
        EncryptedBinaryDataAsBase64: Text;
        ExpectedEncryptedBinaryDataAsBase64: Text;
    begin
        // [GIVEN] With Encryption Key and binary data as Base64
        InitializeCBCEncryption(RijndaelCryptography);
        BinaryDataAsBase64 := GetBinaryDataAsBase64();
        // [WHEN] Encrypt Binary Data
        EncryptedBinaryDataAsBase64 := RijndaelCryptography.EncryptBinaryData(BinaryDataAsBase64);
        ExpectedEncryptedBinaryDataAsBase64 := GetEncryptedBinaryDataAsBase64();
        // [THEN] Verify Result is equal expected value
        LibraryAssert.AreEqual(ExpectedEncryptedBinaryDataAsBase64, EncryptedBinaryDataAsBase64, 'Failed to encrypt binary data.');
    end;

    [Test]
    procedure VerifyDecryptBinaryDataProducesExpectedResult()
    var
        RijndaelCryptography: Codeunit "Rijndael Cryptography";
        EncryptedBinaryDataAsBase64: Text;
        DecryptedBinaryDataAsBase64: Text;
        ExpectedDecryptedBinaryDataAsBase64: Text;
    begin
        // [GIVEN] With Encryption Key and binary data as Base64
        InitializeCBCEncryption(RijndaelCryptography);
        EncryptedBinaryDataAsBase64 := GetEncryptedBinaryDataAsBase64();
        // [WHEN] Decrypt Binary Data
        DecryptedBinaryDataAsBase64 := RijndaelCryptography.DecryptBinaryData(EncryptedBinaryDataAsBase64);
        ExpectedDecryptedBinaryDataAsBase64 := GetBinaryDataAsBase64();
        // [THEN] Verify Result is equal expected value
        LibraryAssert.AreEqual(ExpectedDecryptedBinaryDataAsBase64, DecryptedBinaryDataAsBase64, 'Failed to decrypt binary data.');
    end;

    [Test]
    procedure VerifyEncryptThenDecryptRestoresOriginalData()
    var
        RijndaelCryptography: Codeunit "Rijndael Cryptography";
        BinaryDataAsBase64: Text;
        ResultAsBase64: Text;
    begin
        // [GIVEN] Default Encryption
        BinaryDataAsBase64 := GetBinaryDataAsBase64();
        // [WHEN] Encrypt And Decrypt 
        ResultAsBase64 := RijndaelCryptography.DecryptBinaryData(RijndaelCryptography.EncryptBinaryData(BinaryDataAsBase64));
        // [THEN] Verify Result 
        LibraryAssert.AreEqual(BinaryDataAsBase64, ResultAsBase64, 'Decrypting an encrypted binary data failed.');
    end;

    local procedure InitializeCBCEncryption(var RijndaelCryptography: Codeunit "Rijndael Cryptography")
    begin
        RijndaelCryptography.SetEncryptionData(GetCBCEncryptionKeyAsBase64(), GetCBCInitializationVectorAsBase64());
        RijndaelCryptography.SetBlockSize(128);
        RijndaelCryptography.SetCipherMode('CBC');
        RijndaelCryptography.SetPaddingMode('PKCS7');
    end;

    local procedure GetECP128BitCryptedText(): Text
    begin
        exit('7ah/ajzDcgtEQ/KM54R3udodzz0wHAJrZrK/mFJ+XBA=');
    end;

    local procedure GetECP128BitPlainText(): Text
    begin
        exit('afa1beac1c9f236cf678c392963c4716');
    end;

    local procedure GetECP128BitEncryptionKey(): SecretText
    var
        KeyValue: Text;
    begin
        KeyValue := 'hYRCHMB9TPHu7lIcRsiQ6WmqtaaFGlnF';
        exit(KeyValue);
    end;

    local procedure GetBinaryDataAsBase64(): Text
    begin
        exit('UEsDBBQAAAAIAD1yZVs+1MwDIgAAACAAAAAMAAAARmlsZU5hbWUudHh0S0xLNExKTUw2TLZMMzI2S04zM7dINrY0sjQzTjYxNzQDAFBLAQIUABQAAAAIAD1yZVs+1MwDIgAAACAAAAAMAAAAAAAAAAAAAAAAAAAAAABGaWxlTmFtZS50eHRQSwUGAAAAAAEAAQA6AAAATAAAAAAA');
    end;

    local procedure GetEncryptedBinaryDataAsBase64(): Text
    begin
        exit('Nhl/hypzm6+rQBmAv8piOD9flIp3Wb7ZO+a0m02mdM3Y+2UVKAJHvD6cV6NVSagdEas09MqJ9465aUp/7KSeqM5/0KqcygSsac2IuSsjCry9jveBo5mWGr5De3ylTEOJGW/G6cpk5u6T4g1DTAh9xH9Mu9nihYPrHewqnXKOIhtVw0Ji63rnYiQJSqVn8yYiA6VDnBqawBe0l5rvOSjEqA==');
    end;

    local procedure GetCBCEncryptionKeyAsBase64(): SecretText
    var
        KeyValue: Text;
    begin
        KeyValue := 'cHNGdVR4RUQyY3VSQVRBR2I3b00zTlJzMVBHQzd6UGo=';
        exit(KeyValue);
    end;

    local procedure GetCBCInitializationVectorAsBase64(): Text
    var
        IVValue: Text;
    begin
        IVValue := 'cE80ZUljaFM0N1BzYUhCYw==';
        exit(IVValue);
    end;
}