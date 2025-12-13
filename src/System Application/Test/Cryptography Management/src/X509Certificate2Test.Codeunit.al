// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Security.Encryption;

using System.Security.Encryption;
using System.TestLibraries.Utilities;

codeunit 132587 "X509Certificate2 Test"
{
    Subtype = Test;

    var
        X509CertificateCryptography: Codeunit "X509Certificate2";
        LibraryAssert: Codeunit "Library Assert";

    [Test]
    procedure VerifyCertificateIsInitialized()
    var
        X509ContentType: Enum "X509 Content Type";
        CertBase64Value: Text;
        CertificateVerified: Boolean;
        Password: SecretText;
    begin
        // [SCENARIO] Verify X509 Certificate from Base64 value
        // [GIVEN] Get Test Certificate Base64
        CertBase64Value := GetCertificateBase64();

        // [WHEN] Verify Certificate from Base64 value 
        CertificateVerified := X509CertificateCryptography.VerifyCertificate(CertBase64Value, Password, X509ContentType::Pkcs12);

        // [THEN] Verify that certificate is created
        LibraryAssert.IsTrue(CertificateVerified, 'Failed to verify certificate.');
    end;

    [Test]
    procedure VerifyCertificateFriendlyNameFromBase64Cert()
    var
        CertBase64Value: Text;
        FriendlyName: Text;
        Password: SecretText;
    begin
        // [SCENARIO] Create certificate from Base64, and verify FriendlyName from certificate
        // [GIVEN] Get Test Certificate Base64 value
        CertBase64Value := GetCertificateBase64();

        // [WHEN]  Get Certificate FriendlyName
        X509CertificateCryptography.GetCertificateFriendlyName(CertBase64Value, Password, FriendlyName);

        // [THEN] Certificate Friendly Name is retrieved
        LibraryAssert.AreEqual(FriendlyName, GetFriendlyName(), 'Failed to create certificate.');
    end;

    [Test]
    procedure VerifyCertificateSubjectFromBase64Cert()
    var
        CertBase64Value: Text;
        Subject: Text;
        Password: SecretText;
    begin
        // [SCENARIO] Create certificate from Base64, and verify Subject from certificate
        // [GIVEN] Get Test Certificate Base64 value
        CertBase64Value := GetCertificateBase64();

        // [WHEN]  Get Certificate Subject
        X509CertificateCryptography.GetCertificateSubject(CertBase64Value, Password, Subject);

        // [THEN] Certificate Subject is retrieved
        LibraryAssert.AreEqual(Subject, GetSubject(), 'Failed to create certificate.');
    end;

    [Test]
    procedure VerifyCertificateThumbprintFromBase64Cert()
    var
        CertBase64Value: Text;
        Thumbprint: Text;
        Password: SecretText;
    begin
        // [SCENARIO] Create certificate from Base64, and verify Thumbprint from certificate
        // [GIVEN] Get Test Certificate Base64 value
        CertBase64Value := GetCertificateBase64();

        // [WHEN]  Get Certificate Thumbprint
        X509CertificateCryptography.GetCertificateThumbprint(CertBase64Value, Password, Thumbprint);

        // [THEN] Certificate Thumbprint is retrieved  
        LibraryAssert.AreEqual(Thumbprint, GetThumbprint(), 'Failed to create certificate.');
    end;

    procedure VerifyCertificateIssuerFromBase64Cert()
    var
        CertBase64Value: Text;
        Issuer: Text;
        Password: SecretText;
    begin
        // [SCENARIO] Create certificate from Base64, and verify Issuer from certificate
        // [GIVEN] Get Test Certificate Base64 value
        CertBase64Value := GetCertificateBase64();

        // [WHEN]  Get Certificate Issuer
        X509CertificateCryptography.GetCertificateIssuer(CertBase64Value, Password, Issuer);

        // [THEN] Certificate Issuer is retrieved        
        LibraryAssert.AreEqual(Issuer, GetIssuer(), 'Failed to create certificate.');
    end;

    [Test]
    procedure VerifyCertificateExpirationFromBase64Cert()
    var
        CertBase64Value: Text;
        Expiration: DateTime;
        Password: SecretText;
    begin
        // [SCENARIO] Create certificate from Base64, and verify Expiration Date from certificate
        // [GIVEN] Get Test Certificate Base64 value
        CertBase64Value := GetCertificateBase64();

        // [WHEN]  Get Certificate Expiration in Local Time Zone
        X509CertificateCryptography.GetCertificateExpiration(CertBase64Value, Password, Expiration);

        // [THEN] Certificate Expiration Date is retrieved
        LibraryAssert.AreEqual(Expiration, GetExpirationDateTimeInLocalTimeZone(), 'Wrong certificate Expiration DateTime.');
    end;

    [Test]
    procedure VerifyCertificateNotBeforeFromBase64Cert()
    var
        CertBase64Value: Text;
        NotBefore: DateTime;
        Password: SecretText;
    begin
        // [SCENARIO] Create certificate from Base64, and verify NotBefore Date from certificate
        // [GIVEN] Get Test Certificate Base64 value
        CertBase64Value := GetCertificateBase64();

        // [WHEN]  Get Certificate NotBefore in Local Time Zone
        X509CertificateCryptography.GetCertificateNotBefore(CertBase64Value, Password, NotBefore);

        // [THEN] Certificate NotBefore Date is retrieved        
        LibraryAssert.AreEqual(NotBefore, GetNotBeforeDateInLocalTimeZone(), 'Wrong certificate NotBefore DateTime.');
    end;

    [Test]
    procedure VerifyCertificateHasPrivateKeyFromBase64Cert()
    var
        CertBase64Value: Text;
        HasPrivateKey: Boolean;
        Password: SecretText;
    begin
        // [SCENARIO] Create certificate from Base64, and verify HasPrivateKey from certificate
        // [GIVEN] Get Test Certificate Base64 value
        CertBase64Value := GetCertificateBase64();

        // [WHEN]  Get Certificate HasPrivateKey property value
        HasPrivateKey := X509CertificateCryptography.HasPrivateKey(CertBase64Value, Password);

        // [THEN] Certificate HasPrivateKey property is retrieved
        LibraryAssert.AreEqual(HasPrivateKey, GetHasPrivateKey(), 'Failed to create certificate.');
    end;

    [Test]
    procedure VerifyJsonPropertiesWithCertificate()
    var
        CertBase64Value: Text;
        CertPropertyJson: Text;
        Password: SecretText;
    begin
        // [SCENARIO] Create certificate from Base64, and verify certificate properties from json object
        // [GIVEN] Get Test Certificate Base64
        CertBase64Value := GetCertificateBase64();

        // [WHEN] Return Json object with certificate properties
        X509CertificateCryptography.GetCertificatePropertiesAsJson(CertBase64Value, Password, CertPropertyJson);

        // [THEN] Certificate properties are retrieved
        LibraryAssert.AreEqual(ReturnJsonTokenTextValue(CertPropertyJson, 'FriendlyName'), GetFriendlyName(), 'Failed to create certificate.');
        LibraryAssert.AreEqual(ReturnJsonTokenTextValue(CertPropertyJson, 'Subject'), GetSubject(), 'Failed to create certificate.');
        LibraryAssert.AreEqual(ReturnJsonTokenTextValue(CertPropertyJson, 'Thumbprint'), GetThumbprint(), 'Failed to create certificate.');
        LibraryAssert.AreEqual(ReturnJsonTokenTextValue(CertPropertyJson, 'Issuer'), GetIssuer(), 'Failed to create certificate.');
        LibraryAssert.AreEqual(ReturnJsonTokenTextValue(CertPropertyJson, 'NotAfter'), Format(GetExpirationDateTimeInLocalTimeZone(), 0, 0), 'Wrong certificate Expriation DateTime.');
        LibraryAssert.AreEqual(ReturnJsonTokenTextValue(CertPropertyJson, 'NotBefore'), Format(GetNotBeforeDateInLocalTimeZone(), 0, 0), 'Wrong certificate NotBefore DateTime.');
        LibraryAssert.AreEqual(CheckJsonTokenHasPrivateKey(CertPropertyJson, 'HasPrivateKey'), GetHasPrivateKey(), 'Wrong PrivateKey field in json certificate.');
    end;

    [Test]
    procedure VerifyCertificateIsNotInitialized()
    var
        X509ContentType: Enum "X509 Content Type";
        CertBase64Value: Text;
        Password: SecretText;
    begin
        // [SCENARIO] Try to initialize X509 Certificate from not valid Base64 and catch an error
        // [GIVEN] Get Not Valid Test Certificate Base64
        CertBase64Value := GetNotValidCertificateBase64();

        // [WHEN] Verify Certificate from Base64             
        asserterror X509CertificateCryptography.VerifyCertificate(CertBase64Value, Password, X509ContentType::Pkcs12);

        // [THEN] Verify that certificate is not created
        LibraryAssert.ExpectedError('Unable to initialize certificate!');
    end;

    [Test]
    procedure VerifyCertificateSerialNumber()
    var
        CertBase64Value: Text;
        SerialNumber, SerialNumberASCII : Text;
        Password: SecretText;
    begin
        // [SCENARIO] Get certificate serial number as hex and ascii
        // [GIVEN] Certificate Base64
        CertBase64Value := GetCertificateBase64();

        // [WHEN] Retrieving cert serial number
        X509CertificateCryptography.GetCertificateSerialNumber(CertBase64Value, Password, SerialNumber);
        // [THEN] Verifying if serial number match the expected one
        LibraryAssert.AreEqual('65C2091E54AB879948654BB906FD377F', SerialNumber, 'Cert serial number is not correct');

        // [WHEN] Converting hex to ascii
        X509CertificateCryptography.GetCertificateSerialNumberAsASCII(CertBase64Value, Password, SerialNumberASCII);
        // [THEN] Verifying that hex convertion to ascii was correct
        LibraryAssert.AreEqual('eÂ	T«HeK¹ý7', SerialNumberASCII, 'Converting hex to ascii is not correct.');
    end;

    [Test]
    procedure GetCertificatePublicKeyAsBase64String()
    var
        CertBase64Value: Text;
        Password: SecretText;
        PublicKey: Text;
    begin
        // [SCENARIO] Get certificate public key as a Base64 string

        // [GIVEN] Get a certificate as Base64 string
        CertBase64Value := GetCertWithPrivateKeyBase64();

        // [WHEN] Retrieve the public key from the certificate
        PublicKey := X509CertificateCryptography.GetCertificatePublicKeyAsBase64String(CertBase64Value, Password);

        // [THEN] The retrieved public key matches the certificates public key
        LibraryAssert.AreEqual(GetCertificatePublicKeyBase64(), PublicKey, 'Certificate public key is not correct.');
    end;

    [Test]
    procedure GetRawCertificateDataDoesNotContainPrivateKey()
    var
        CertBase64Value: Text;
        RawCertData: Text;
        Password: SecretText;
        PublicKey: Text;
    begin
        // [SCENARIO] GetRawCertDataAsBase64String returns public certificate information and does not contain the private key

        // [GIVEN] A pfx certificate containing the private key
        CertBase64Value := GetCertWithPrivateKeyBase64();

        // [GIVEN] Make sure that the original certificate contains the private key
        LibraryAssert.IsTrue(X509CertificateCryptography.HasPrivateKey(CertBase64Value, Password), 'Certificate must contain private key.');

        // [WHEN] Get raw certificate data
        RawCertData := X509CertificateCryptography.GetRawCertDataAsBase64String(CertBase64Value, Password);

        // [THEN] The certificate data is a Cert certificate format containing the same public key as  the original pfx certificate
        PublicKey := X509CertificateCryptography.GetCertificatePublicKeyAsBase64String(RawCertData, Password);
        LibraryAssert.AreEqual(PublicKey, GetCertificatePublicKeyBase64(), 'Certificate public key is not correct.');

        // [THEN] The exported certificate data do not contain the private key
        LibraryAssert.IsFalse(X509CertificateCryptography.HasPrivateKey(RawCertData, Password), 'Exported certificate data must not contain private key.');
    end;

    local procedure ReturnJsonTokenTextValue(CertPropertyJson: Text; PropertyName: Text): Text
    var
        JObject: JsonObject;
        JToken: JsonToken;
    begin
        JObject.ReadFrom(CertPropertyJson);
        JObject.Get(PropertyName, JToken);
        exit(JToken.AsValue().AsText());
    end;

    local procedure CheckJsonTokenHasPrivateKey(CertPropertyJson: Text; PropertyName: Text): Boolean
    var
        JObject: JsonObject;
        JToken: JsonToken;
    begin
        JObject.ReadFrom(CertPropertyJson);
        JObject.Get(PropertyName, JToken);
        exit(JToken.AsValue().AsText() = 'Yes');
    end;

    local procedure GetCertificateBase64(): Text
    begin
        exit(
            'MIICngIBAzCCAloGCSqGSIb3DQEHAaCCAksEggJHMIICQzCCAj8GCSqGSIb3' +
            'DQEHBqCCAjAwggIsAgEAMIICJQYJKoZIhvcNAQcBMBwGCiqGSIb3DQEMAQMw' +
            'DgQIW/ELQaGSk90CAgfQgIIB+JzlK5d/9oejtAXHFrQI/coOxX+QDr7WJ99R' +
            'x3NzO1WOBhlUGiAm+IdPBKsgxKr1IALPh5RFaJ57LxD9AyCysPq+OgVeiISz' +
            '7FNxVxaBwE3dz46ybcqagCFvVfka9fOTJa2PsFTEI+ILYJeYZM4rwebdE+nU' +
            'yQgYOUfnzOnNgvDdnEspMpOJoWLQzFowD1fsZfbEebsegWE//qTEOj1cVQa6' +
            'IFNP5DP+vqLPv8meYcohp0IRfSYOfSWmdK60HHfFPVi4xJBNGdEw+DIsQeEa' +
            'OJdDLjMY/dUcBVLEnmSBAehTLDiM6nnEgIdLzVw4GUpRiS4cKo5sHRj9f9lY' +
            'juW0HXapF7WxfDaNGLGg72MzkMUUPBpfCg0mv+agZbIE/XDTTOcn6Y0GxxYI' +
            'eoZvijinLiauURz6drZ+ygenCwwLNX+r/RWqY9CxI5J0TT4Xr3MNAagzF9ux' +
            'C14+j1Ym3tok6CY51NojFsI9iugYmNghkRTUCCx2Y1cEVmYdO+3FWYacUax1' +
            'G3bLOIDMqMV8pMXq6UxUPbWFq2Latl180cchF1gD/Ag2O6FNz0uawogboknp' +
            'lC+v1MrLJlt4t2WTXMpeF+hgV2oGI7fyGMJLlPZPRpfBbdRpiJiRytA/ekM9' +
            'FY+52y81f3tp1jzFnmpw7t281UOcUxH8akRnnDA7MB8wBwYFKw4DAhoEFDZv' +
            'N1bsFHxc5ROOhtks5GjPfx15BBT7Wsk8zUbkmHIStc4+1HIP57RRGgICB9A=');
    end;

    local procedure GetCertWithPrivateKeyBase64(): Text
    begin
        // A self-signed PFX certificate with a private key valid until January 2053
        exit(
            'MIIQzwIBAzCCEIUGCSqGSIb3DQEHAaCCEHYEghByMIIQbjCCBloGCSqGSIb3DQEHBqCCBkswggZHAgEAMIIGQAYJKoZIhvcNAQcBMF8GCSqGSIb3DQEFDTBS' +
            'MDEGCSqGSIb3DQEFDDAkBBBS2bdIBgQOlLWUH8KKwDnqAgIIADAMBggqhkiG9w0CCQUAMB0GCWCGSAFlAwQBKgQQZgNomt4lNtJyeG5lgQCCE4CCBdD6BMKQ' +
            '1jpudsbfeOjMKYCfsnwFJjFeT6S8SfEVTaJYsPWGI3m5ivfHemUI8No2k2SXmdFlDwb9Mj8lweuP1rXG/5cd3l6Nrsc2+9bD7NbNYMW84w8dSBBFhCI2Hw5N' +
            'hyW3fpLw8lNGbet03m07D5fXwSOqIv9iL7e1Pew/3nmrv2RhgUGI+qrHE8qW/RkPXV9URgt0XvIXt9BAzxri7JWh5UIiTCXCdZlwHPGgxH4TvVp/GsyrmFd6' +
            'Knbh9ml11nGQRjqnnOeYSXmxdVVZw3AcKzD6gqgmug42qvymvDsEdRc10ZPyXfuVErYA9QBNkXIEnt0+K2uD3mp8qsRzqeC/fynztIn9PU14GWSCuwLTUM7G' +
            '0fmltmTHW+9mkSqJmiFz8MSpd1UzeY/lrDKsJDB1RBU0iAoMI472PDtvGETraFDIyw2PHIGq8x6l5bzKaUBRPTJsAnzFHo4Gas/4uxLbhTiI/oVBxs0td21h' +
            'COP2/wWKFm3khG8W/eLSV/lF4pWhH3VOSvef0hjtJS7JejxdOs6+OCJPqkwUB+nTFbFSS0z789EleeSXs6s8B73GERnRzOawzaMFOfM5l24PfR6N5tIyq8Vn' +
            '+/nuMUZwAgjuxZon+AZSzzlhIlKb+CZ8OZiyLrDCB36kXeofqIwBoAT/OoOkLaspxW2ajJmJpU50PNyLwJAPpvnBqBTZ95z0jbtyJY8pBA89TQndwxyOUls9' +
            'FK+WeaTwjzr/85uQDHS8PRuD9bncAqWRLkFAoGTcRjz7VwU3s7We3OOgSmkaO4DaFTcIxRMPyB4+14ZAN5F0RpOYLyfuSpcL2upmanDThT4CDembJdIZhWyb' +
            'kJO3E4H8jivbDGrqUCUjeYvdGF/PvkRg9TfLcym8X3nR85yKmenC9O/2Ve7yDah1MylG5tLSuqQOO8jMxQb/AKoptlY2ewOj3gJw27d239TMTv+FT0d4aVcW' +
            'N2i+Nu1/bStIeMpUT6xP43Xx2nszPonUwtQ+WgAeGi3VRqN7XvCb+FD15fhEUMSiaSMZvF14c4b4B+4e8iMXGvkDtj18SDDHC5fck9Bd8wsE0UiCKE4b3nTD' +
            'zCC0okrnQmngVfjSh0nOqNG0Pqdm4SfWXIG47AHkcYpLEnEV+gd/aExXHk/nr9ayoyiRO3U0WwAoparnHCH88bMp/4c1ZkQdgHkKZcB9eEJYDAVdV3RjW8QO' +
            'zASUF2S2xyksJcKq8/BJMpMUf193VGOrshL8MbLUj2I6mXpOoFZvVoNPrNtkrd19UPcD2987wXyTazQGYDQE1mZjeunyN1O9mhIbTQRx7dMrlqsYeGU1Kh+x' +
            'pmgT5yuVfEI7D15c/pqVtdfn6iql1fQHxXsO7rAEvqrX4ICVsMe70slaIZsDoJSE5dw1FxP5tXZVmQtwRoC2zMK/ENFoNKzNtI5L9tyi0Icza+M65/1o6/+D' +
            'RejfppKAAbgwds6NmOCuIAajM86f4+o2L6evccrOxxtpDQH55ODefW5xyGiuV225bv0apQe8ibtUQ0lFBE5DiezA1WqAw71qgkdN02rCWniuT8zT6QY6Faxe' +
            '+dyGhslJq5SlajlH861zwXaI3YmpUfnm2nGxLRsvBUK2KbBMJn/HQeelgIztvvarVwxMo7mbn1/WK34oGdKYPUz9FvUT6c5gqsmaYMQ7Q6QMHJ2rDxYSi7xI' +
            'lOVoCYtD5iXtQaDyv053S6KsZfBdY0ik3AFl69DxoVoDPndwg5OY14Gb7Wi5yWTv4k20uUEfko7WiP2mnzES1GbwMjWtqDLxmU16hGNSDkvggI70WOV9YBQ1' +
            'm/soyoJrCpihjzjxWZrFXMOAL5O1ItUluTekj9j5XQfKUSEQXcMhTjlIiPR/bkbdg1bgk0Hb4Jqtm0Du8Y+6iLfpE/lqr6W21ivfvsCdS+MWH00sAtRpIs7e' +
            'l4669HEMCwP3AoULtZQONKs27ttnaaIradf1a0KYuXQuskQ9q2Z5PJjEN+AwggoMBgkqhkiG9w0BBwGgggn9BIIJ+TCCCfUwggnxBgsqhkiG9w0BDAoBAqCC' +
            'Cbkwggm1MF8GCSqGSIb3DQEFDTBSMDEGCSqGSIb3DQEFDDAkBBDKbYLctEs+BA0oXCVGKExqAgIIADAMBggqhkiG9w0CCQUAMB0GCWCGSAFlAwQBKgQQn/1V' +
            '67TJ26dVKscs3WExRwSCCVC/IE1tg1+NLYE5qhlZkeu7xDc9HTRls9c6s51FUtGjVTblW2kYuCCS6RL9uTl0trjQ5OCN3VvzbFbYKCPKfUT6/x8U3z4h5uYH' +
            'lJPDQkOt8J9DNMb20KMbv07CEWFaoTn6cIgHh9aKgZb5BfHxU9uCj4dy3q7qsRjtCp7viXQ2cAkpJ/GXeh8x67ch+btIlT5KxJasZKZUTwXRg6KxKA22EWWt' +
            '1eUnelkKAauIsEkZPBmn27k3tJGXzzKkBqKHUl9nYjmfvcH4ezev5MwslTnyFVjmIpytgE/t8IoMwmYkZfGwX6SDPavPzDJDI2DrlrJ2kqRoAR/0BAVsNNHE' +
            'u5IBsiqtOTgSpj1ORWNzd/nB+JlTTCGpbeLQ41vxZaS8sCPrH5h/K2+5P4PVkhAp0QaacSH9kqfmaThkNs9Og4oOK+6LAuxieGz1Z0jaQlge/QJNO+nRLvYj' +
            'cXGoGgolUcZCp/E4z10rj8wXaZU+u7ChsXkkLhR4xgWNGyO0St8u60H6HWXeQ9MMCnQtxO7y2ya/lLpfFPHzcNj0W92bTp3SqCuaF3Nh0jvs7z6AUbHBDtN0' +
            'tPcmWEzE+wOIe8MW7DohS3kwXjnXZhZDJK5Ehyt1hTd5L2CEG6kSQSPkMyh2/TeKkJINv9zVwc/CBYZ90/TwQ2Jqre6ABZP7rZ+Zmt85ImRVNMqOLJX1Vmlh' +
            'pmWacfLOYa+cVuZJSS5M8SC+9scmCBHO4uqnxv3hwTmSf8eMej1r2FURvQpeAPfWwhFlzr9yPFysjUQfTcHEppEk3wZS5ETUvsGsgKGiUnt8p9Zkchw0hfkX' +
            'uaeqfL94XGISPpUHptTya8yX4XvZUzvG/ET7vNWWKMegWYjxxYIUDx/lVhuzJ/Sil4AISu+5sel9BrGlAOh2OQybLRPA9wINFV6xJMQPdJtDz6pvL7PAC0sn' +
            'pzAFxNognS8EacVSwPmi1PH6OQFhwTADuT7U/BU/ao4Pmn3Y7LnC64NWjKYf8tHR6ueY0p1e034JXHaJg20HW7G3IUIWA3w+jMUFa+KABEwI2b5d2lkIujn2' +
            'd8fxkFgDovZ7Tl11QDz91xlHxSfWNXzUvpOdK3ISrjJAcky0myPlxiqit6RnNa0u2nBeAKCB4IShghb+0l/8xCWxvJijK12yXxTKhWflIv0u81L2bcJSEAoD' +
            'Xxuj9F38oQdgqeHJZPI1UJLP+9V/ZD8Av8MX1/iXNAhWipHBmzE4zgENBT2z6xzr6jvqKBAx//Iz9w8lX+Bi1ex4Ys85QscICNKKOTSbBxvC0D8CKIi9ZJTN' +
            '1PF1Nny59pB+EJcGwPu9b24GBB+wCTsJRTp7QBjk/tgVoq9i16lwfLpqSGSM0lLT4XxxUN98q8t3UpKW1kHSrQojgpsCbMbmeFvSDxSrhBBviA3TpvckS/SD' +
            '6gYLtXyKLEBMvjBvQR1SCgtxEP+BbhcqU3HJy207MyTRUiihl/rVsv8zendIpM5VRgbkwnJxFh+is1XDTVZyNeoOod1raHwHGkI1iAlYWEhR30Vxu/q3wVvs' +
            'e/25u2AvkXxv6i7+ie+HxubbSmW6Lfuzk3FjpNnGCLxXezviXItdJ6H737QNKvvTRLRinJyPfwQaYfg1Vki85BUv+tB5cW9qevWPTSCqjevq7ndFYQ+j3lZV' +
            'kNG5z38rm9vloxDyZKrdQvRGeQeIEehVAx5uVmAgqFwLJ2JJ6OxFXo9G0PJb3Q/tPOxi8Ueu+yxds0T0lxRTq6UVAWnGmeZyNwSMCr1/mSDoLBnHLO+FuyRQ' +
            'LIrObVy6p3XC2Tmle4y01/6OhJpSrAyN26L1b5qiU9NRX8adE5fCg/ruXI/m1qeQm+0ZAD0baT1HxsVdgA5lYYs4e7Y5xIaFW2MQ8sv356y13slEBiHxMqfJ' +
            'gfz5OqQj/NjsAU3ZOTfVCPf//UEzI3hAMTknVyHNBbc4zz8ckpy65TlxUjX3gYqq9/fBwL5qPSePXEefeGZFDxuy81tYEWXV9GRntMNkcQHcA1SWlhaT3E64' +
            '08YuTh2fo0fDSUqterGWaYeboGCNhSFzxWPzm+osZ6xAfAhgmiy/iHq3Lx/f9H3k/aGr/GEtfbj8PVJPw8opRNIK7ui7Fjh/cEywglTXHkLWLSL+1fKe6ttv' +
            'x99SEZ9UYNKs8IBtsZZ2qcKdnPIPg1miiqvovsQYIU4KkvkLNGGqDSkAGjtiNjNVnXuXBF/jb1KmGOPUeG+r3uteVjutHEmJ+mvEDf7uELWblQ3jHcZq5dML' +
            'L2ZNKkDfqX6T4aYCsePqU/ofFOwK3VNP0b4yMcBlf23rTBM3myedtftbREuRS8FVt46N/l5FrIm0Ciij8bdewQ/qs4/dv2SGyxlyhvOXLOIx+sAUstrTwaI1' +
            'IzrOcsv1xMA4ekTJnaH+lmaF/To3uqcxOGFLkrfj4uXLM/n2+7IUJcxvOg7MQxaazMEv1wbeO81inuhUxp/Sun+V8689dGnMtx9xTmyJr1/FoyqgHjozvTGZ' +
            'gNMLOlPc7oDnJxt9zesjU43/kGKbDIsmYXhPYG1Gy3KFSifvOaZda3ZYmSzKSCTMqvtfrVssQD9bgKpsDgaN46rInGjQxmXYhRK9bb/T+6Qckzdei9IGTVB0' +
            'NvvcHS3fLmJmyr2ZsWbdjKW3BfEFcsG37EGR8xZeCA4k86FkCggeuVhDCfv5FioOlWo2RXExIeM11i9129QQeR/CgodYzsclByKMzUtOvKG+mp7ptXVcyzUE' +
            'VnvHniPXllIxBwdsLQqyk9P+PWjLwgJcGMSArU6Oar6Hf0hK7jiM2KxV5RHFA9PVyMOql3M7cRtYAvmx+hesCGKny27otQD2lHgVpnSYVak7Uek9/2pTSgaf' +
            '6ghk3z8WdrFsrXXR7m+vQ1l8Cp9m9K4b7hzCQ/k+khNVI4hmbruf67be5vQddEpLVJ7C+Kes4IzNtM5DFttHmK+zYLE/UfWZdAUjuO1MjAS9MokvH783uYTp' +
            '3STSbuOMfg4cg+YWNLaVrlR1FqhbjzyaZTGvwR1i1Hkq4na+g3PPM3p/L/fp1he68N6WCKyRgRVeU6Aq/HesDiLJvNd9MP9l5nTucbA6AbcLkCa+xdIIJ0xo' +
            'gP2W+KGcL35FkG3vHRQ3THRFYYY+bdm5z+/qgY/oY0v+yNdV4lR6qpLf6OW81eo6Ndg5TA7BdO/oNsQ43zElMCMGCSqGSIb3DQEJFTEWBBQBSJzVt9Dqxvcp' +
            'iHsnUx1PBq0CeTBBMDEwDQYJYIZIAWUDBAIBBQAEIDrstOHQn47YSN/4dXMhYtbB/Rl4bKEqLDdr6W8mcwF0BAhQ8JxitXWssAICCAA='
        );
    end;

    local procedure GetCertificatePublicKeyBase64(): Text
    begin
        // Public key for the certificate returned by GetCertWithPrivateKeyBase64
        exit(
            'MIICCgKCAgEAxdwvNLqQtF/R1rUY/pnYJlTSidX1NhFyQ2Z4va3+y33xycxfJlMlWEjyX5Yu1Bd6iaOYeJ7v3sHsahuVZR1c8lWaN2jJ6J4bS9sx5NVqk8pu' +
            'ULerOWzUb0XQP5K7H4GxzraayUTn/zCHqMs6oxoRKxZogXS3P8dsIscaIBynRRTWWUTBffBmDt1pH8ncU3fTn6/zm5X9oeOwJcavTIKlPX6w5ZTK/rlEId5y' +
            'n9B5NxS8tCt5lTsh4LtlsMPI6jjWU+feJvIB/fEZP8mRV8hHzg/AZq6iIDe7lU/hKyDvKPxkDPMn/UeFUwlD6f0peYM+5HIhZwTa356GuNT7lnoq61vMyocl' +
            'rp8kftKIc7/1GGfM8khY3Ip/AcBDUKF3jXxEHW7ERallNuzWx0joFTDig51BmVE7LuRpfvIkrfXYH29ZFGakLVLTufPEOWMaDrboQUPPSD390P8/pMZhdoW7' +
            'fpaOajXK1xaA0GbecrzETdHjNbvxNHHOODWDJG3dAxRV6x26Z/uvXp/QJfnTvXppK7OBVh0Zc1G58cE+N9BvTXu/SGIYeh9DU228yH0viJK8gsvviJK5Ku+P' +
            'ayZeZw0QWB9DK6YOHTywSlJ9rVpRxCKilhyUu6bsg8XXssh/JOTL+DPPPxIyan+CQr0dxovv3BciVUo4c/EioCwBdXomcAcCAwEAAQ=='
        );
    end;

    local procedure GetNotValidCertificateBase64(): Text
    begin
        exit('svZ2agE126JHsQ0bhzN5TKsYfbwfTwfjdWAGy6Vf1nYi/rO+ryMO');
    end;

    local procedure GetFriendlyName(): Text
    begin
        exit('');
    end;

    local procedure GetSubject(): Text
    begin
        exit('CN=Joe''s-Software-Emporium');
    end;

    local procedure GetThumbprint(): Text
    begin
        exit('55A0AE83959E7245E0A04FA1BA5F4024AE0D1235');
    end;

    local procedure GetIssuer(): Text
    begin
        exit('CN=Root Agency');
    end;

    local procedure GetExpirationDateTimeInLocalTimeZone(): DateTime
    begin
        exit(CreateDateTime(20291231D, 220000T) + OffsetToLocalTimeZone());
    end;

    local procedure GetNotBeforeDateInLocalTimeZone(): DateTime
    begin
        exit(CreateDateTime(20191231D, 220000T) + OffsetToLocalTimeZone());
    end;

    local procedure OffsetToLocalTimeZone(): Duration
    var
        TimeZoneInfo: DotNet TimeZoneInfoTest;
    begin
        TimeZoneInfo := TimeZoneInfo.Local;
        exit(TimeZoneInfo.BaseUtcOffset());
    end;

    local procedure GetHasPrivateKey(): Boolean
    begin
        exit(false);
    end;
}
