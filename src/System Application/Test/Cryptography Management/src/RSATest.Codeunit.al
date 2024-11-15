// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Security.Encryption;

using System.Security.Encryption;
using System.Text;
using System.Utilities;
using System.TestLibraries.Utilities;

codeunit 132617 "RSA Test"
{
    Subtype = Test;

    var
        LibraryAssert: Codeunit "Library Assert";
        Base64Convert: Codeunit "Base64 Convert";
        Any: Codeunit Any;
        IsInitialized: Boolean;
        PrivateKeyXmlStringSecret: SecretText;

    local procedure Initialize()
    var
        RSA: Codeunit RSA;
    begin
        if IsInitialized then
            exit;
        RSA.InitializeRSA(2048);
        PrivateKeyXmlStringSecret := RSA.ToSecretXmlString(true);
        IsInitialized := true;
    end;

    [Test]
    procedure InitializeKeys()
    var
        RSA: Codeunit RSA;
        KeyXml: XmlDocument;
        Root: XmlElement;
        Node: XmlNode;
        KeyXmlText: SecretText;
    begin
        RSA.InitializeRSA(2048);
        KeyXmlText := RSA.ToSecretXmlString(true);

        LibraryAssert.IsTrue(XmlDocument.ReadFrom(GetXmlString(KeyXmlText), KeyXml), 'RSA key is not valid xml data.');
        LibraryAssert.IsTrue(KeyXml.GetRoot(Root), 'Could not get Root element of key.');

        LibraryAssert.IsTrue(Root.SelectSingleNode('Modulus', Node), 'Could not find <Modulus> in key.');
        LibraryAssert.IsTrue(Root.SelectSingleNode('DQ', Node), 'Could not find <DQ> in key.');
    end;

    [Test]
    procedure TestSignDataAndVerifyDataWithMD5AndPSS()
    begin
        LibraryAssert.IsTrue(SignAndVerifyData(enum::"Hash Algorithm"::MD5, enum::"RSA Signature Padding"::Pss), 'Failed to verify signed data');
    end;

    [Test]
    procedure TestSignDataAndVerifyDataWithMD5AndPkcs1()
    begin
        LibraryAssert.IsTrue(SignAndVerifyData(enum::"Hash Algorithm"::MD5, enum::"RSA Signature Padding"::Pkcs1), 'Failed to verify signed data');
    end;

    [Test]
    procedure TestSignDataAndVerifyDataWithSHA1AndPSS()
    begin
        LibraryAssert.IsTrue(SignAndVerifyData(enum::"Hash Algorithm"::SHA1, enum::"RSA Signature Padding"::Pss), 'Failed to verify signed data');
    end;

    [Test]
    procedure TestSignDataAndVerifyDataWithSHA1AndPkcs1()
    begin
        LibraryAssert.IsTrue(SignAndVerifyData(enum::"Hash Algorithm"::SHA1, enum::"RSA Signature Padding"::Pkcs1), 'Failed to verify signed data');
    end;

    [Test]
    procedure TestSignDataAndVerifyDataWithSHA256AndPSS()
    begin
        LibraryAssert.IsTrue(SignAndVerifyData(enum::"Hash Algorithm"::SHA256, enum::"RSA Signature Padding"::Pss), 'Failed to verify signed data');
    end;

    [Test]
    procedure TestSignDataAndVerifyDataWithSHA256AndPkcs1()
    begin
        LibraryAssert.IsTrue(SignAndVerifyData(enum::"Hash Algorithm"::SHA256, enum::"RSA Signature Padding"::Pkcs1), 'Failed to verify signed data');
    end;

    [Test]
    procedure TestSignDataAndVerifyDataWithSHA384AndPSS()
    begin
        LibraryAssert.IsTrue(SignAndVerifyData(enum::"Hash Algorithm"::SHA384, enum::"RSA Signature Padding"::Pss), 'Failed to verify signed data');
    end;

    [Test]
    procedure TestSignDataAndVerifyDataWithSHA384AndPkcs1()
    begin
        LibraryAssert.IsTrue(SignAndVerifyData(enum::"Hash Algorithm"::SHA384, enum::"RSA Signature Padding"::Pkcs1), 'Failed to verify signed data');
    end;

    [Test]
    procedure TestSignDataAndVerifyDataWithSHA512AndPSS()
    begin
        LibraryAssert.IsTrue(SignAndVerifyData(enum::"Hash Algorithm"::SHA512, enum::"RSA Signature Padding"::Pss), 'Failed to verify signed data');
    end;

    [Test]
    procedure TestSignDataAndVerifyDataWithSHA512AndPkcs1()
    begin
        LibraryAssert.IsTrue(SignAndVerifyData(enum::"Hash Algorithm"::SHA512, enum::"RSA Signature Padding"::Pkcs1), 'Failed to verify signed data');
    end;

    local procedure SignAndVerifyData(HashAlgorithm: Enum "Hash Algorithm"; RSASignaturePadding: Enum "RSA Signature Padding"): Boolean
    var
        TempBlob, TempBlobStringToSign : Codeunit "Temp Blob";
        RSA: Codeunit RSA;
        SignatureOutStream, StringToSignOutStream : OutStream;
        SignatureInStream, StringToSignInStream : InStream;
        XMLString: SecretText;
        PlainText: Text;
    begin
        // [SCENARIO] Sign random text and verify the signed signature
        TempBlob.CreateInStream(SignatureInStream);
        TempBlob.CreateOutStream(SignatureOutStream);

        TempBlobStringToSign.CreateOutStream(StringToSignOutStream);
        PlainText := SaveRandomTextToOutStream(StringToSignOutStream);
        TempBlobStringToSign.CreateInStream(StringToSignInStream);

        RSA.InitializeRSA(2048);
        XMLString := RSA.ToSecretXmlString(true);
        RSA.SignData(XMLString, StringToSignInStream, HashAlgorithm, RSASignaturePadding, SignatureOutStream);
        TempBlobStringToSign.CreateInStream(StringToSignInStream);

        SignatureInStream.Position(1);
        StringToSignInStream.Position(1);
        exit(RSA.VerifyData(XMLString, StringToSignInStream, HashAlgorithm, RSASignaturePadding, SignatureInStream));
    end;


    [Test]
    procedure DecryptEncryptedTextWithOaepPadding()
    var
        RSA: Codeunit RSA;
        EncryptingTempBlob: Codeunit "Temp Blob";
        EncryptedTempBlob: Codeunit "Temp Blob";
        DecryptingTempBlob: Codeunit "Temp Blob";
        EncryptingInStream: InStream;
        EncryptingOutStream: OutStream;
        EncryptedInStream: InStream;
        EncryptedOutStream: OutStream;
        DecryptedInStream: InStream;
        DecryptedOutStream: OutStream;
        PlainText: Text;
    begin
        // [SCENARIO] Verify decrypted text with OAEP padding encryption.
        Initialize();

        // [GIVEN] With RSA pair of keys, plain text and its encryption stream
        EncryptingTempBlob.CreateOutStream(EncryptingOutStream);
        PlainText := SaveRandomTextToOutStream(EncryptingOutStream);
        EncryptingTempBlob.CreateInStream(EncryptingInStream);
        EncryptedTempBlob.CreateOutStream(EncryptedOutStream);
        RSA.Encrypt(PrivateKeyXmlStringSecret, EncryptingInStream, true, EncryptedOutStream);
        EncryptedTempBlob.CreateInStream(EncryptedInStream);

        // [WHEN] Decrypt encrypted text stream
        DecryptingTempBlob.CreateOutStream(DecryptedOutStream);
        RSA.Decrypt(PrivateKeyXmlStringSecret, EncryptedInStream, true, DecryptedOutStream);
        DecryptingTempBlob.CreateInStream(DecryptedInStream);

        // [THEN] Decrypted text is the same as the plain text
        LibraryAssert.AreEqual(PlainText, Base64Convert.FromBase64(Base64Convert.ToBase64(DecryptedInStream)),
         'Unexpected decrypted text value.');
    end;

    [Test]
    procedure DecryptEncryptedTextWithPKCS1Padding()
    var
        RSA: Codeunit RSA;
        EncryptingTempBlob: Codeunit "Temp Blob";
        EncryptedTempBlob: Codeunit "Temp Blob";
        DecryptingTempBlob: Codeunit "Temp Blob";
        EncryptingInStream: InStream;
        EncryptingOutStream: OutStream;
        EncryptedInStream: InStream;
        EncryptedOutStream: OutStream;
        DecryptedInStream: InStream;
        DecryptedOutStream: OutStream;
        PlainText: Text;
    begin
        // [SCENARIO] Verify decrypted text with PKCS#1 padding encryption.
        Initialize();

        // [GIVEN] With RSA pair of keys, plain text and its encryption stream
        EncryptingTempBlob.CreateOutStream(EncryptingOutStream);
        PlainText := SaveRandomTextToOutStream(EncryptingOutStream);
        EncryptingTempBlob.CreateInStream(EncryptingInStream);
        EncryptedTempBlob.CreateOutStream(EncryptedOutStream);
        RSA.Encrypt(PrivateKeyXmlStringSecret, EncryptingInStream, false, EncryptedOutStream);
        EncryptedTempBlob.CreateInStream(EncryptedInStream);

        // [WHEN] Decrypt encrypted text stream
        DecryptingTempBlob.CreateOutStream(DecryptedOutStream);
        RSA.Decrypt(PrivateKeyXmlStringSecret, EncryptedInStream, false, DecryptedOutStream);
        DecryptingTempBlob.CreateInStream(DecryptedInStream);

        // [THEN] Decrypted text is the same as the plain text
        LibraryAssert.AreEqual(PlainText, Base64Convert.FromBase64(Base64Convert.ToBase64(DecryptedInStream)),
         'Unexpected decrypted text value.');
    end;

    [Test]
    procedure DecryptWithOAEPPaddingTextEncryptedWithPKCS1Padding()
    var
        RSA: Codeunit RSA;
        EncryptingTempBlob: Codeunit "Temp Blob";
        EncryptedTempBlob: Codeunit "Temp Blob";
        DecryptingTempBlob: Codeunit "Temp Blob";
        EncryptingInStream: InStream;
        EncryptingOutStream: OutStream;
        EncryptedInStream: InStream;
        EncryptedOutStream: OutStream;
        DecryptedOutStream: OutStream;
    begin
        // [SCENARIO] Decrypt text encrypted with use of PKCS#1 padding, using OAEP padding.
        Initialize();

        // [GIVEN] With RSA pair of keys, plain text and encryption stream
        EncryptingTempBlob.CreateOutStream(EncryptingOutStream);
        SaveRandomTextToOutStream(EncryptingOutStream);
        EncryptingTempBlob.CreateInStream(EncryptingInStream);
        EncryptedTempBlob.CreateOutStream(EncryptedOutStream);
        RSA.Encrypt(PrivateKeyXmlStringSecret, EncryptingInStream, false, EncryptedOutStream);
        EncryptedTempBlob.CreateInStream(EncryptedInStream);

        // [WHEN] Decrypt encrypted text stream using OAEP Padding
        DecryptingTempBlob.CreateOutStream(DecryptedOutStream);
        asserterror RSA.Decrypt(PrivateKeyXmlStringSecret, EncryptedInStream, true, DecryptedOutStream);
    end;

    [Test]
    procedure DecryptWithPKCS1PaddingTextEncryptedWithOAEPPadding()
    var
        RSA: Codeunit RSA;
        EncryptingTempBlob: Codeunit "Temp Blob";
        EncryptedTempBlob: Codeunit "Temp Blob";
        DecryptingTempBlob: Codeunit "Temp Blob";
        EncryptingInStream: InStream;
        EncryptingOutStream: OutStream;
        EncryptedInStream: InStream;
        EncryptedOutStream: OutStream;
        DecryptedOutStream: OutStream;
    begin
        // [SCENARIO] Decrypt text encrypted with use of OAEP padding, using PKCS#1 padding.
        Initialize();

        // [GIVEN] With RSA pair of keys, plain text, padding and encryption stream
        EncryptingTempBlob.CreateOutStream(EncryptingOutStream);
        SaveRandomTextToOutStream(EncryptingOutStream);
        EncryptingTempBlob.CreateInStream(EncryptingInStream);
        EncryptedTempBlob.CreateOutStream(EncryptedOutStream);
        RSA.Encrypt(PrivateKeyXmlStringSecret, EncryptingInStream, true, EncryptedOutStream);
        EncryptedTempBlob.CreateInStream(EncryptedInStream);

        // [WHEN] Decrypt encrypted text stream using PKCS#1 padding.
        DecryptingTempBlob.CreateOutStream(DecryptedOutStream);
        asserterror RSA.Decrypt(PrivateKeyXmlStringSecret, EncryptedInStream, false, DecryptedOutStream);
    end;

    local procedure SaveRandomTextToOutStream(OutStream: OutStream) PlainText: Text
    begin
        PlainText := Any.AlphanumericText(Any.IntegerInRange(80));
        OutStream.WriteText(PlainText);
    end;

    [NonDebuggable]
    local procedure GetXmlString(XmlString: SecretText): Text
    begin
        exit(XmlString.Unwrap());
    end;
}