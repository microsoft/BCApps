// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Security.Encryption;

using System.Security.Encryption;
using System.TestLibraries.Utilities;
using System.Text;
using System.Utilities;

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
        DecryptedInStream: InStream;
        DecryptedOutStream: OutStream;
        PlainText: Text;
        DecryptedText: Text;
        DecryptionFailed: Boolean;
    begin
        // [SCENARIO] Decrypt text encrypted with use of PKCS#1 padding, using OAEP padding.
        // [SCENARIO] Due to random padding, decryption may occasionally not throw but returns garbage data.
        Initialize();

        // [GIVEN] With RSA pair of keys, plain text and encryption stream
        EncryptingTempBlob.CreateOutStream(EncryptingOutStream);
        PlainText := SaveRandomTextToOutStream(EncryptingOutStream);
        EncryptingTempBlob.CreateInStream(EncryptingInStream);
        EncryptedTempBlob.CreateOutStream(EncryptedOutStream);
        RSA.Encrypt(PrivateKeyXmlStringSecret, EncryptingInStream, false, EncryptedOutStream);
        EncryptedTempBlob.CreateInStream(EncryptedInStream);

        // [WHEN] Decrypt encrypted text stream using OAEP Padding
        DecryptingTempBlob.CreateOutStream(DecryptedOutStream);
        DecryptionFailed := not TryDecryptWithOaepPadding(RSA, PrivateKeyXmlStringSecret, EncryptedInStream, DecryptedOutStream);

        // [THEN] Either decryption fails with an exception, or the decrypted text is garbage (not equal to plaintext)
        if not DecryptionFailed then begin
            DecryptingTempBlob.CreateInStream(DecryptedInStream);
            DecryptedText := Base64Convert.FromBase64(Base64Convert.ToBase64(DecryptedInStream));
            LibraryAssert.AreNotEqual(PlainText, DecryptedText, 'Decryption failed with garbage data.');
        end else
            LibraryAssert.IsTrue(DecryptionFailed, 'Decryption failed with wrong padding.');
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
        DecryptedInStream: InStream;
        DecryptedOutStream: OutStream;
        PlainText: Text;
        DecryptedText: Text;
        DecryptionFailed: Boolean;
    begin
        // [SCENARIO] Decrypt text encrypted with use of OAEP padding, using PKCS#1 padding.
        // [SCENARIO] Due to random padding, decryption may occasionally not throw but returns garbage data.
        Initialize();

        // [GIVEN] With RSA pair of keys, plain text, padding and encryption stream
        EncryptingTempBlob.CreateOutStream(EncryptingOutStream);
        PlainText := SaveRandomTextToOutStream(EncryptingOutStream);
        EncryptingTempBlob.CreateInStream(EncryptingInStream);
        EncryptedTempBlob.CreateOutStream(EncryptedOutStream);
        RSA.Encrypt(PrivateKeyXmlStringSecret, EncryptingInStream, true, EncryptedOutStream);
        EncryptedTempBlob.CreateInStream(EncryptedInStream);

        // [WHEN] Decrypt encrypted text stream using PKCS#1 padding.
        DecryptingTempBlob.CreateOutStream(DecryptedOutStream);
        DecryptionFailed := not TryDecrypt(RSA, PrivateKeyXmlStringSecret, EncryptedInStream, DecryptedOutStream);

        // [THEN] Either decryption fails with an exception, or the decrypted text is garbage (not equal to plaintext)
        if not DecryptionFailed then begin
            DecryptingTempBlob.CreateInStream(DecryptedInStream);
            DecryptedText := Base64Convert.FromBase64(Base64Convert.ToBase64(DecryptedInStream));
            LibraryAssert.AreNotEqual(PlainText, DecryptedText, 'Decryption failed with garbage data.');
        end else
            LibraryAssert.IsTrue(DecryptionFailed, 'Decryption failed with wrong padding.');
    end;

    [TryFunction]
    local procedure TryDecryptWithOaepPadding(RSA: Codeunit RSA; XmlString: SecretText; EncryptedInStream: InStream; DecryptedOutStream: OutStream)
    begin
        RSA.Decrypt(XmlString, EncryptedInStream, true, DecryptedOutStream);
    end;

    [TryFunction]
    local procedure TryDecrypt(RSA: Codeunit RSA; XmlString: SecretText; EncryptedInStream: InStream; DecryptedOutStream: OutStream)
    begin
        RSA.Decrypt(XmlString, EncryptedInStream, false, DecryptedOutStream);
    end;

    [Test]
    procedure ImportFromPemPrivateKeyAndSignData()
    var
        RSA1: Codeunit RSA;
        RSA2: Codeunit RSA;
        TempBlobData: Codeunit "Temp Blob";
        TempBlobSignature: Codeunit "Temp Blob";
        DataOutStream: OutStream;
        SignatureOutStream: OutStream;
        DataInStream: InStream;
        SignatureInStream: InStream;
        PemPrivateKey: SecretText;
    begin
        // [SCENARIO] A private RSA key exported as PEM can be imported and used to sign data that is verifiable with the matching public key.

        // [GIVEN] An RSA instance with a generated key pair and its private key in PEM format
        RSA1.InitializeRSA(2048);
        PemPrivateKey := RSA1.ExportRSAPrivateKeyPem();

        // [GIVEN] Random data to sign
        TempBlobData.CreateOutStream(DataOutStream);
        SaveRandomTextToOutStream(DataOutStream);
        TempBlobData.CreateInStream(DataInStream);

        // [WHEN] A new RSA instance imports the PEM private key and signs the data
        RSA2.ImportFromPem(PemPrivateKey);
        TempBlobSignature.CreateOutStream(SignatureOutStream);
        RSA2.SignData(DataInStream, Enum::"Hash Algorithm"::SHA256, Enum::"RSA Signature Padding"::Pkcs1, SignatureOutStream);

        TempBlobData.CreateInStream(DataInStream);
        TempBlobSignature.CreateInStream(SignatureInStream);

        // [THEN] The signature can be verified using the first instance's stateful verify (same key loaded)
        LibraryAssert.IsTrue(RSA2.VerifyData(DataInStream, Enum::"Hash Algorithm"::SHA256, Enum::"RSA Signature Padding"::Pkcs1, SignatureInStream),
            'Signature must be valid after ImportFromPem with a private key.');
    end;

    [Test]
    procedure ImportFromPemPublicKeyAndVerifyData()
    var
        RSA1: Codeunit RSA;
        RSA2: Codeunit RSA;
        RSA3: Codeunit RSA;
        TempBlobData: Codeunit "Temp Blob";
        TempBlobSignature: Codeunit "Temp Blob";
        DataOutStream: OutStream;
        SignatureOutStream: OutStream;
        DataInStream: InStream;
        SignatureInStream: InStream;
        PemPublicKey: Text;
        PrivateXmlKey: SecretText;
    begin
        // [SCENARIO] A public RSA key exported as PEM can be imported and used to verify a signature.

        // [GIVEN] An RSA key pair with its public key in PEM and private key in XML
        RSA1.InitializeRSA(2048);
        PemPublicKey := RSA1.ExportRSAPublicKeyPem();
        PrivateXmlKey := RSA1.ToSecretXmlString(true);

        // [GIVEN] Data signed using the private key (XML-based)
        TempBlobData.CreateOutStream(DataOutStream);
        SaveRandomTextToOutStream(DataOutStream);
        TempBlobData.CreateInStream(DataInStream);
        TempBlobSignature.CreateOutStream(SignatureOutStream);
        RSA2.SignData(PrivateXmlKey, DataInStream, Enum::"Hash Algorithm"::SHA256, Enum::"RSA Signature Padding"::Pkcs1, SignatureOutStream);

        TempBlobData.CreateInStream(DataInStream);
        TempBlobSignature.CreateInStream(SignatureInStream);

        // [WHEN] A new RSA instance imports the PEM public key and verifies the signature
        RSA3.ImportFromPem(PemPublicKey);

        // [THEN] Verification succeeds
        LibraryAssert.IsTrue(RSA3.VerifyData(DataInStream, Enum::"Hash Algorithm"::SHA256, Enum::"RSA Signature Padding"::Pkcs1, SignatureInStream),
            'Signature must be verifiable after ImportFromPem with a public key.');
    end;

    [Test]
    procedure ExportAndImportRSAPrivateKeyPem()
    var
        RSA1: Codeunit RSA;
        RSA2: Codeunit RSA;
        PemPrivateKey: SecretText;
        XmlFromOriginal: SecretText;
        XmlFromImported: SecretText;
    begin
        // [SCENARIO] A private key roundtrips losslessly through ExportRSAPrivateKeyPem and ImportFromPem.

        // [GIVEN] An RSA instance with a generated private key
        RSA1.InitializeRSA(2048);
        XmlFromOriginal := RSA1.ToSecretXmlString(false);

        // [WHEN] The private key is exported to PEM and imported into a new instance
        PemPrivateKey := RSA1.ExportRSAPrivateKeyPem();
        RSA2.ImportFromPem(PemPrivateKey);

        // [THEN] The public key XML exported from the new instance matches the original
        XmlFromImported := RSA2.ToSecretXmlString(false);
        LibraryAssert.AreEqual(GetXmlString(XmlFromOriginal), GetXmlString(XmlFromImported),
            'Public key XML must be identical after PEM roundtrip.');
    end;

    [Test]
    procedure ExportRSAPublicKeyPemContainsPemHeader()
    var
        RSA1: Codeunit RSA;
        PublicKeyPem: Text;
    begin
        // [SCENARIO] ExportRSAPublicKeyPem returns a well-formed PEM string with the correct header.

        // [GIVEN] An initialized RSA instance
        RSA1.InitializeRSA(2048);

        // [WHEN] The public key is exported as PEM
        PublicKeyPem := RSA1.ExportRSAPublicKeyPem();

        // [THEN] The result contains a valid PEM header and footer
        LibraryAssert.IsTrue(PublicKeyPem.Contains('-----BEGIN RSA PUBLIC KEY-----'),
            'PEM public key must start with RSA PUBLIC KEY header.');
        LibraryAssert.IsTrue(PublicKeyPem.Contains('-----END RSA PUBLIC KEY-----'),
            'PEM public key must end with RSA PUBLIC KEY footer.');
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