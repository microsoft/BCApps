// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Security.Encryption;

using System.Security.Encryption;
using System.Text;
using System.Utilities;
using System.TestLibraries.Utilities;

codeunit 132613 RSACryptoServiceProviderTests
{
    Subtype = Test;

    var
        LibraryAssert: Codeunit "Library Assert";
        RSACryptoServiceProvider: Codeunit RSACryptoServiceProvider;
        Base64Convert: Codeunit "Base64 Convert";
        Any: Codeunit Any;
        IsInitialized: Boolean;
        PrivateKeyXmlStringSecret: SecretText;
        PublicKeyXmlString: Text;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;
        PrivateKeyXmlStringSecret := Base64Convert.FromBase64('PFJTQUtleVZhbHVlPjxNb2R1bHVzPmNKMHBpL2ZBcXJTRy9TZTUrZGdzcksyNjNwSUkvQjhieGZyWDBoMm1aN0VZUWhURXhYa2d6Z0xwS3dFRWFmdUs0MFVqUjEzNlNLQ3I5S240aHpPek1zam5hMXJJRXJCUnMzcU5IS1NxS3JzdkhaUTljRFo3RElVekh2cVh0Q01KMFo0clFBZlZLcWl2bGZqd3RJR1ZPSXRKK0RMT1E4S2tZNjJiOTI2YzhMTEtGUG5SU1ZxQnQrL3lGbEJ3M1NlQWdNYzBtaXRKRUhvYW5LdExXc3RLVzlDTW55OWc1R1V2cnZaY0wwUjR4NkpabFlGTVMwQnBmdFJNbmFrbnI3VXpxMGdvWnY4OHhmb1IrTW1ud1ZUOWdTU0ZRRW1rOVRHaVdjdUV1bnFNUmZ4b3htQW0zVGt3RTRMSDVDNHVNMWRlUGVnWDM0bmoyZmphOWhpUWtReHVqdz09PC9Nb2R1bHVzPjxFeHBvbmVudD5BUUFCPC9FeHBvbmVudD48UD5zSW5SbG0wSGRWeTMrUlo0NDhLNTZaSVNDdkNQNlVMZGZJMk10RU96MlZ2cUN2Z0Vham1BckJkYmYzaUVFNUlXRWhNbEtRRGJCVktZdVMvcW1hanROc202cVhUMXFiRldIdGRQcGNmQ3BMeVFHT2Y0dStFb2xnK2FIWFlIYytNejdSdjBIOSt2NUlxejVWMzZ0ck11N0Q4clF5QVNMeHR2L3BYZ1ZDVzRpUk09PC9QPjxRPm8wMXpmb0UxazBzdmdhRGNzUHEzNWxPaTlsV25LVWUvNzA2eDdjeDNES1drQmR4aUhOSDJFVjhsTVhnS2hra2s2YmNocWo3dXNaQi9OdVBZaER0TWRsYnd3REdkTmFmZ09qKy94Q2loUEFRaFo3T3l5M01sb3hOemsrWHlZUzg4VjVOdFhiSmkrelpmSHJWbXowR2xmczJoNHVSZ0ZEZWw3cVBZUW5GSUVCVT08L1E+PERQPmY3TFJob3hMYnR1b3dHYysveEdtUll4QnZPUVNWVnJtdCtmME5aa2JpVWp4WFFuV3Q3ZnNtWTh6d2xzOHZxTlhqNitGbThsZ3BOTUFZa1NFNEszUEdXaUd1M2s5RW9pU2tUQ1NEb3NYQXU3YkZRa0haWEFUV2FqamhCZ1NnQU9EVmlwNFJtNFozNmx0UTZiZGFqYm01RUUxWEJMZzFHNTJicU9mWjM3NW96MD08L0RQPjxEUT5WTC94WEluNklBTTVHSEUvbDZuR253Wnc0Sjc3TGZWS3F3dVFVL1YxSTE4ampOY2ZKQTNqUW9pNmFMMy8yRWxGbXZXcnh3cjZIYlQ4RUtTV3phbG91VkhOaURFM2dZMHFWWkNZR1Zsc3RCVUFzUzBWY1hqRTQ2bElwazBFU1dPV1VXejFxVmJXLzhEc0JLZm9QMCsyYitTUVM0eHlRSXZRMWRTNmUyRUhJVEU9PC9EUT48SW52ZXJzZVE+Z1lvNmZtSEl0bGtZcG4wWWRSUE9icVRmZURhZm96WnMxaWQ3S2lORWRIakx1MkN3NmhnZEpXVjArUXlSdFFzZDMraTM2eFc2d3FQMmg3QVRsQkJ0cEhLU2lmTmo2VGRSWUEvVUZsZldsWm1yUzdoWjdNQ3FaMmlUNTVQZjJWa3k3RUEwdFY2a1pvOENvRzdYRWtmU2tadzR0Q2hGN1Nja0FTSWF0US9aY2RNPTwvSW52ZXJzZVE+PEQ+T2xGNVdZM0ZEZUlOWWY1M3RpWTRCSGkzcEZsMkk3S3NmRnVKOXJyNkdRckNLRDUvSkZDMUoxcWtpMnVzY0lJZWk5R2JFbk5ka016OEgra0IxbXAwcTZFVkR5aGxJaUNEUHZJQkw4c3FnSlNOTXNFNUMrcDYwS0lPTmtYSjJEU28rZy95RCtlK2dhZjN2aSs3MzQ2WHl6OSszL1RYa29teS9oZkRCR0VaRHlDbnZnN2gyRUdzRnh4N1RRbVdneWxoT3YweTdaQXp5Q0Rmc3JEUy90Mk8rcHNoWm9PYkpWZGVlVlNlaVF4QVZLYTNFTzdJRHFLNm5pSHV2azhOMVgyejBBYWFWaVlJUDdJZ0JXMmdZNXJwcTlRa25HZHhxb2I2VHFvQlV4aFBSM2VVblAvbWhnOWlXejZiNW42RnhsR2tSVkxSMndjaVQ1Z25TMzFjaEJ3cXVRPT08L0Q+PC9SU0FLZXlWYWx1ZT4=');
        PublicKeyXmlString := Base64Convert.FromBase64('PFJTQUtleVZhbHVlPjxNb2R1bHVzPmNKMHBpL2ZBcXJTRy9TZTUrZGdzcksyNjNwSUkvQjhieGZyWDBoMm1aN0VZUWhURXhYa2d6Z0xwS3dFRWFmdUs0MFVqUjEzNlNLQ3I5S240aHpPek1zam5hMXJJRXJCUnMzcU5IS1NxS3JzdkhaUTljRFo3RElVekh2cVh0Q01KMFo0clFBZlZLcWl2bGZqd3RJR1ZPSXRKK0RMT1E4S2tZNjJiOTI2YzhMTEtGUG5SU1ZxQnQrL3lGbEJ3M1NlQWdNYzBtaXRKRUhvYW5LdExXc3RLVzlDTW55OWc1R1V2cnZaY0wwUjR4NkpabFlGTVMwQnBmdFJNbmFrbnI3VXpxMGdvWnY4OHhmb1IrTW1ud1ZUOWdTU0ZRRW1rOVRHaVdjdUV1bnFNUmZ4b3htQW0zVGt3RTRMSDVDNHVNMWRlUGVnWDM0bmoyZmphOWhpUWtReHVqdz09PC9Nb2R1bHVzPjxFeHBvbmVudD5BUUFCPC9FeHBvbmVudD48L1JTQUtleVZhbHVlPg==');
        IsInitialized := true;
    end;

    [Test]
    procedure InitializeKeys()
    var
        KeyXml: XmlDocument;
        Root: XmlElement;
        Node: XmlNode;
        KeyXmlText: SecretText;
    begin
        RSACryptoServiceProvider.InitializeRSA(2048);
        KeyXmlText := RSACryptoServiceProvider.ToSecretXmlString(true);

        LibraryAssert.IsTrue(XmlDocument.ReadFrom(GetXmlString(KeyXmlText), KeyXml), 'RSA key is not valid xml data.');
        LibraryAssert.IsTrue(KeyXml.GetRoot(Root), 'Could not get Root element of key.');

        LibraryAssert.IsTrue(Root.SelectSingleNode('Modulus', Node), 'Could not find <Modulus> in key.');
        LibraryAssert.IsTrue(Root.SelectSingleNode('DQ', Node), 'Could not find <DQ> in key.');
    end;

    [Test]
    procedure TestSignDataWithCert()
    var
        TempBlob: Codeunit "Temp Blob";
        CryptographyManagement: Codeunit "Cryptography Management";
        X509Certificate2: Codeunit X509Certificate2;
        SignatureOutStream: OutStream;
        SignatureInStream: InStream;
        CertBase64Value: Text;
    begin
        CertBase64Value := GetTestCertWithPrivateKey();
        TempBlob.CreateInStream(SignatureInStream);
        TempBlob.CreateOutStream(SignatureOutStream);

        LibraryAssert.IsTrue(X509Certificate2.HasPrivateKey(CertBase64Value, GetPasswordAsSecret()), 'Cert must have private key to test signing');
        CryptographyManagement.SignData('Test data', X509Certificate2.GetCertificatePrivateKey(CertBase64Value, GetPasswordAsSecret()), enum::"Hash Algorithm"::SHA256, SignatureOutStream);

        LibraryAssert.IsTrue(CryptographyManagement.VerifyData('Test data', X509Certificate2.GetCertificatePublicKey(CertBase64Value, GetPasswordAsSecret()), enum::"Hash Algorithm"::SHA256, SignatureInStream), 'Failed to verify signed data');
    end;

    [Test]
    procedure DecryptEncryptedTextWithOaepPadding()
    var
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
        RSACryptoServiceProvider.Encrypt(GetPublicKeyXmlStringAsSecret(), EncryptingInStream, true, EncryptedOutStream);
        EncryptedTempBlob.CreateInStream(EncryptedInStream);

        // [WHEN] Decrypt encrypted text stream
        DecryptingTempBlob.CreateOutStream(DecryptedOutStream);
        RSACryptoServiceProvider.Decrypt(PrivateKeyXmlStringSecret, EncryptedInStream, true, DecryptedOutStream);
        DecryptingTempBlob.CreateInStream(DecryptedInStream);

        // [THEN] Decrypted text is the same as the plain text
        LibraryAssert.AreEqual(PlainText, Base64Convert.FromBase64(Base64Convert.ToBase64(DecryptedInStream)),
         'Unexpected decrypted text value.');
    end;

    [Test]
    procedure DecryptEncryptedTextWithPKCS1Padding()
    var
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
        RSACryptoServiceProvider.Encrypt(GetPublicKeyXmlStringAsSecret(), EncryptingInStream, false, EncryptedOutStream);
        EncryptedTempBlob.CreateInStream(EncryptedInStream);

        // [WHEN] Decrypt encrypted text stream
        DecryptingTempBlob.CreateOutStream(DecryptedOutStream);
        RSACryptoServiceProvider.Decrypt(PrivateKeyXmlStringSecret, EncryptedInStream, false, DecryptedOutStream);
        DecryptingTempBlob.CreateInStream(DecryptedInStream);

        // [THEN] Decrypted text is the same as the plain text
        LibraryAssert.AreEqual(PlainText, Base64Convert.FromBase64(Base64Convert.ToBase64(DecryptedInStream)),
         'Unexpected decrypted text value.');
    end;

    [Test]
    procedure DecryptWithOAEPPaddingTextEncryptedWithPKCS1Padding()
    var
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
        RSACryptoServiceProvider.Encrypt(GetPublicKeyXmlStringAsSecret(), EncryptingInStream, false, EncryptedOutStream);
        EncryptedTempBlob.CreateInStream(EncryptedInStream);

        // [WHEN] Decrypt encrypted text stream using OAEP Padding
        DecryptingTempBlob.CreateOutStream(DecryptedOutStream);
        asserterror RSACryptoServiceProvider.Decrypt(PrivateKeyXmlStringSecret, EncryptedInStream, true, DecryptedOutStream);

        // [THEN] Error occures
        LibraryAssert.ExpectedError('A call to System.Security.Cryptography.RSACryptoServiceProvider.Decrypt failed with this message: Cryptography_OAEPDecoding');
    end;

    [Test]
    procedure DecryptWithPKCS1PaddingTextEncryptedWithOAEPPadding()
    var
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
        RSACryptoServiceProvider.Encrypt(GetPublicKeyXmlStringAsSecret(), EncryptingInStream, true, EncryptedOutStream);
        EncryptedTempBlob.CreateInStream(EncryptedInStream);

        // [WHEN] Decrypt encrypted text stream using PKCS#1 padding.
        DecryptingTempBlob.CreateOutStream(DecryptedOutStream);
        asserterror RSACryptoServiceProvider.Decrypt(PrivateKeyXmlStringSecret, EncryptedInStream, false, DecryptedOutStream);

        // [THEN] Error occures
        LibraryAssert.ExpectedError('A call to System.Security.Cryptography.RSACryptoServiceProvider.Decrypt failed with this message: The parameter is incorrect.');
    end;

    local procedure SaveRandomTextToOutStream(OutStream: OutStream) PlainText: Text
    begin
        PlainText := Any.AlphanumericText(Any.IntegerInRange(80));
        OutStream.WriteText(PlainText);
    end;

    local procedure GetTestCertWithPrivateKey(): Text
    begin
        exit(Base64Convert.FromBase64('TUlJS0FBSUJBekNDQ2J3R0NTcUdTSWIzRFFFSEFhQ0NDYTBFZ2dtcE1JSUpwVENDQmdZR0NTcUdTSWIzRFFFSEFhQ0NCZmNFZ2dYek1JSUY3ekNDQmVzR0N5cUdTSWIzRFFFTUNnRUNvSUlFL2pDQ0JQb3dIQVlLS29aSWh2Y05BUXdCQXpBT0JBalU4aDZiSFNUZEN3SUNCOUFFZ2dUWURPOXJuRkoxZndIR3N2MHByQUw5eUh3SWtXT3ZnUFZFT2Z5c0JacHAzdk1QaTJEcWlqUzV3ME44cEhNYkJ4UmZyRFZCdjMxbC9CRXpIQlpud0hTbCt3NndtT3NyN1R0RncyUUtVZUhLZmh1YUUyL0twUERaZlgzcE5oTUozOUFWaTJ5U0QwZUNLSk9Ob0JNeGRVZEFyeDU1NGpVVmZsYWJDQlh6TXExMVZLN1U4bnluOFQ1S0pmWmpCSWQ3MjhSUGgvNVVPemErYkpBa0VMNy9rQWNmMW9RM1ArUmlEYzU2d3djN0VyM1Vzc2cvcXdRbG5UdUhsb0pCNjRGbnRvMVdEK0xYTUtkY3I2TzJpOVZpUUtlWDhuSlJ6TnpTMVN1UkFyZHU1QVZ4azEwQS91Nkd6YUR5VGlISzdjdWFCWFlzbW5pVmVmWkRGekhqTjkrQkVsZG4wYWZtSkxORi9LeXdNQUhIRmZ0RGhGUGVpa01DUGpmNVQ4cU9CbmQ3RGx1Z3JVdzFvNnJkQ1dLNVlmTkM5d0VVOGpHU29CMERYd1ZhUTNqdGowbEZva2ZvSVJOaXhkK0FDemlHWitPQXR5RDdYc05NOVU0NkZSMXVncUV1OVBJanFvUVVQTTYyeC9ubnNPQk5qWHN6eHEwM1k0bEpKa0lBNjRCSmNJWnRhUlUraXdVaWk2ampKdHBNMzZ5MS9MNVB4d3JGOFAycGxEY2RLbjFobTUvQUltOXpTYSttT0Q5UXdsalY5TVRuYkRvQ0JTNGxrNjFHWndmQVpsNjJGbGpJa1ZyeFE0QXF0NEg0aDNCVjRhU2pPZWNPcjlSVVd0Sld4Nm5OWDQwbjlpczFJMTFjd1pXbGJVUmFVMEhKdCt3U3ZxbHV3YTZMZkFjYm5WSTNwcWkzSC9ZanNaMUYwdUdpVFpEU2VxeEw3ZEZrMURNUlNvZEhBZXZCcnJkMHVlalhIUExFYXVmQlI5eFk0bXNsT0luWkJ5TExlbkUyY25xN3JDaFBWSEhJcDhVZjhHWmo0WkYvVThLZ3dBQVVPZFpLUmh4QkFEU0lKclEyYVJ2OThkWTJYTXEvZ0lLZ2hueFpWT2xzQnFycUdqb1JQSUprMDdVOVIzOWVYR2hJekRKNkJvWTVOWnM3ZURJY0pRaG4xL1kxcG9JbmZSODFQVFBVbjdqM05GMFFISFYrYmovMUhNNGlJc1lpcVh1M01SSExtSWg4RU9kVG4rVGJ2NkYxVTdQVVBUOE1xVDQzNkkwWkxFam1zRmhjVEkzVTB2QlBqbTZPeUdiTVpZQllCTmgyR1hHWDRGeDRWVlk3UUo1cEFQazRsSS8yMDJMR3MwSkJsVzhRV2RoMkVSN0tiVzFERS9nY0ZsQVMzWGxnUGQzNnVRRFZ0aFJMK2R1SkZuTXYzTi9ZWVpKWnJ2TzhiMkdXWWN2bjdrbWY2bjdldXpCbUdCUU9WdUdqZmIzQWlUZ2ZBZzJ2cXdpN0k4NjhkOUw4NWRnZFJlNXlmV3p4alNsbkZ4TE52WVVpT3ZheHhtOFNNZ2p6NXhhZlNTVkpRT0VoNGFkRWFlT0lLRXRMSWpia3lPcFVXS0I1VFd6RHl6b2t0N28zOE02dHhwdUtXcWRpM0dwR2lyRHA1R1grV2NsM0hmMUdSL1ZIQVlVc1lCUmlSVVFxY0R2RE9WNnBHM29GUExUUTh0TFdpTDJQMjdMeWNQYkxaNlVrYTkwRWI5N1RITVMza2hjeUFRcVZLb1lyQVIvdDFKL2Q0ajcvVjc2QnNUTS81c2ZKNE9GcVZJTUFzUk5oWkQ1angyUEdzTHlaSFcyMW1ibjhnVmRnWitXY01aWWpxU05TMmpLKzZ5bTVEdHYrK2pYVkhIMG1hQkhyRitEOURjZlYvaHZ6TU82Rm04Tmg1V1VMdXp3ZXVSS1pDWmdFS1o5RXRrVFhKUTB0bkd6ZFRlc2R6ZjAzeTJxUFBiZktpN0dCdWYwTGlEbHFUdVVTeTkvanc5c0k5Zy9QaEI5NkoxWFNETUt4S0lLbHVPL0oxaGlnK2p4TG9PWUJtZ2dJT3J5L3NTalgxVnhETS9yQ050NTQ4eExQbGZ6WVUrTFJpZFRWSjlRS1g1MGg3b1U4SHVZOEZ6UWh2aTFZc2FFdVliNnVBV3JrQWpERVNqR0RaTjBodHBtU0JDNzkrL0gxclJaOGRzbXNkVDNTZ1RHQjJUQVRCZ2txaGtpRzl3MEJDUlV4QmdRRUFRQUFBREJkQmdrcWhraUc5dzBCQ1JReFVCNU9BSFFBWlFBdEFETUFNd0JpQUdZQVlRQm1BREVBWmdBdEFHVUFaZ0F3QURnQUxRQTBBR1FBT0FCbEFDMEFZUUJqQURVQVl3QXRBR1VBTWdBM0FEQUFNQUEzQUdNQU5BQXlBRFVBTkFCak1HTUdDU3NHQVFRQmdqY1JBVEZXSGxRQVRRQnBBR01BY2dCdkFITUFid0JtQUhRQUlBQkNBR0VBY3dCbEFDQUFRd0J5QUhrQWNBQjBBRzhBWndCeUFHRUFjQUJvQUdrQVl3QWdBRkFBY2dCdkFIWUFhUUJrQUdVQWNnQWdBSFlBTVFBdUFEQXdnZ09YQmdrcWhraUc5dzBCQndhZ2dnT0lNSUlEaEFJQkFEQ0NBMzBHQ1NxR1NJYjNEUUVIQVRBY0Jnb3Foa2lHOXcwQkRBRURNQTRFQ0lWOTI5T1NGYW9FQWdJSDBJQ0NBMUM1S2xhTldMOHA4SW5kUzVwQ1dmNm5MbVZtTTNxbHVjTDVhYmZKUDUrYTY1emJoZllWcXV2VmhvaTJjVisxU3hvL2o1dFhpUFZVSXhxalBWYS8zRFAvVVdTOUd2OWFhd2Q4ek5vWXQ3b1ZQN0p4bm5STlJTalNlSHdNWXhJRWlhZFhnQXJpRkdoSDF4QTlKSFZJejFHTUxZbDBQRG9vclFBdmpUMlhZNEhWcElEWjU3NW1zOHZaYjBvUWNvOXRXOVRYYmtkdkpxdUJTY1NsamtrQkZyK1kxNTR6bzh3YnI5Tmp1V1ozanQ3OFpxWUpHRzFSbVVhdDBucFhGNnBpZDBjVXJEYXlDeFlQWlF5UVk0WXZjMTdkKzZtb2xyRER3UGJNVDVxaTRRRHJFU0N2bWRMMEpmK2FUclJLOCtxb1VxWURPeEVZZ2NEcVJ2bllWY1lEZVVVWlluOTdRcmNpQXdMcWxSTUlOT1JvMUNUY29IRFlPKzRsb3U0aWROV3h0TEd2NHRlRHVYcXZNa2Q2cldpYmw4Q0JjTEVIZUx3UGJhcUgybklhUkI2RWJGNUVTYmRvbURla2l0Q0puYWIzck0yeUdYWndsUy9jb1RwYkM2Y0dXekYyZGwwUjVvRER3Y1ZaN2FldGZjc2JkL1czbEg2Y01Temg2L3dqQjJ4cmU5Q2ExTTdRMHRuWjJrUC9wRHZiUXVmSHNTMXQ3bzF5VDRmQ08yMDJOVFBoc3V5N0dEMlByWmN0cGJyRS9YV3BNV0FWSmJJVlVaTlBnandpMk8zVGtNREtldkNrL2VtZUlta2x2ZjBiSUtWaEtvYXJzZExCUUNkajR6bms3MFgwaERveWN4YmNoTU9TUjhGMGp1WTlaWGNwOHhpSE5oV2xvcFBZWHM0alpiVmFzNDZrbENoSnlLYWVQUzdYWnpQVnk3ZGkydVcraEFXZTJoYmdoMk1PSnUyTGNjT2pLdUozckNjSlp0bjFSNGJsa1dSaVQ5a1NIN09mek4xTFlTcDg0ak55RU5FNzNmRVV4SFplTVVkYVYxdGVEaEtRMXlFWm0xQk85SjdvRGkvOVg5b1h5VFhub1c5MVVrWE1iS0xWMjZqRTk5aWFod3dFaSt4OE5MNmFqN2xsWE9Wd056aDliVFJPVHNRUTNNMERvY0R0d05KZ0JBTjlieHRuZFBUcUxMNFMzdUQwWHdxM1NodURsd2w2ZlB2bmJ0R21MckJuaWFWb2dENUF6R01QMTB6Tm1EQXJzeGtMZy9DMTVnRkROTjdTMkJsbUJqbWY5ZGNDZ2I2V3huSEp4VUxkMGwweU1ZZlFqRFNFZVN3eFlCdHh5NFh6ck1CeTR1YzZuRmNRODM1RS9YR2tmTnFJd1ByTzJpV3hZZlh2YTFYbkVKbXJaRlY2N2NOaXppaDY1LytQcXJwTVk4WVNsKzRiOVoycnVWVnN5QmEwVm9aWVcrQTR6b2U3ZnIyUktoTDFTZjRCTlRUbHl1b01EczNDM0RBN01COHdCd1lGS3c0REFob0VGQkcvKzZ0UVhibENtV3JtbWVrMmhVTGJXN295QkJTOEROb0ZjMEsxcTVwR1JwTU1UcGZRK01SODB3SUNCOUE9'));
    end;

    local procedure GetPasswordAsSecret(): SecretText
    var
        PasswordPlain: Text;
    begin
        PasswordPlain := 'testcert';
        exit(PasswordPlain);
    end;

    local procedure GetPublicKeyXmlStringAsSecret(): SecretText
    var
        XmlString: Text;
        SecretXmlString: SecretText;
    begin
        XmlString := PublicKeyXmlString;
        SecretXmlString := XmlString;
        exit(SecretXmlString);
    end;

    [NonDebuggable]
    local procedure GetXmlString(XmlString: SecretText): Text
    begin
        exit(XmlString.Unwrap());
    end;
}