// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Security.Encryption;

using System.Security.Encryption;
using System.TestLibraries.Utilities;
codeunit 132612 "Signed Xml Module Test"
{
    Subtype = Test;

    var
        SignedXml: Codeunit SignedXml;
        LibraryAssert: Codeunit "Library Assert";

    [Test]
    procedure CheckXmlSignatureUsingKeyInSignature()
    var
        SignedXmlDocument: XmlDocument;
        SignatureElement: XmlElement;
    begin
        GetValidSignedXml(SignedXmlDocument);
        GetSignatureElement(SignedXmlDocument, SignatureElement);

        SignedXml.InitializeSignedXml(SignedXmlDocument);
        SignedXml.LoadXml(SignatureElement);

        LibraryAssert.IsTrue(SignedXml.CheckSignature(), 'Failed to verify the xml signature.');
    end;

    [Test]
    procedure CheckInvalidXmlSignatureUsingKeyInSignature()
    var
        SignedXmlDocument: XmlDocument;
        SignatureElement: XmlElement;
    begin
        GetInvalidSignedXml(SignedXmlDocument);
        GetSignatureElement(SignedXmlDocument, SignatureElement);

        SignedXml.InitializeSignedXml(SignedXmlDocument);
        SignedXml.LoadXml(SignatureElement);

        LibraryAssert.IsFalse(SignedXml.CheckSignature(), 'Signature verified even though it is invalid.');
    end;

    [Test]
    procedure VerifyXmlSignatureUsingKeyXmlString()
    var
        XmlString: SecretText;
        SignedXmlDocument: XmlDocument;
        SignatureElement: XmlElement;
    begin
        GetValidSignedXml(SignedXmlDocument);
        GetSignatureElement(SignedXmlDocument, SignatureElement);

        SignedXml.InitializeSignedXml(SignedXmlDocument);
        SignedXml.LoadXml(SignatureElement);

        GetSignatureKeyXmlString(XmlString);
        LibraryAssert.IsTrue(SignedXml.CheckSignature(XmlString), 'Failed to verify the xml signature.');
    end;

    [Test]
    procedure VerifyXmlSignatureUsingCertificate()
    var
        SignedXmlDocument: XmlDocument;
        SignatureElement: XmlElement;
        CertBase64Data: Text;
        Password: SecretText;
    begin
        GetValidSignedXml(SignedXmlDocument);
        GetSignatureElement(SignedXmlDocument, SignatureElement);

        SignedXml.InitializeSignedXml(SignedXmlDocument);
        SignedXml.LoadXml(SignatureElement);

        CertBase64Data := GetCertificateData();

        LibraryAssert.IsTrue(SignedXml.CheckSignature(CertBase64Data, Password, true), 'Failed to verify the xml signature.');
    end;

    [Test]
    procedure SetXmlDSigC14NTranform()
    var
        SignatureKey: Codeunit "Signature Key";
        XmlToSign: XmlDocument;
        KeyText: SecretText;
        Signature: XmlElement;
        NamespaceMgr: XmlNamespaceManager;
        Node: XmlNode;
        SignatureNamespaceUriTok: Label 'http://www.w3.org/2000/09/xmldsig#', Locked = true;
        C14NTransformUriTok: Label 'http://www.w3.org/TR/2001/REC-xml-c14n-20010315', Locked = true;
    begin
        XmlDocument.ReadFrom('<XmlData Id="ID01">This is a document</XmlData>', XmlToSign);
        GetSignatureKeyXmlString(KeyText);
        SignatureKey.FromXmlString(KeyText);

        SignedXml.InitializeSignedXml(XmlToSign);
        SignedXml.SetSigningKey(SignatureKey);
        SignedXml.InitializeReference('#ID01');
        SignedXml.SetCanonicalizationMethod(SignedXml.GetXmlDsigC14NTransformUrl());
        SignedXml.AddXmlDsigC14NTransformToReference(false);
        SignedXml.AddReferenceToSignedXML();

        SignedXml.ComputeSignature();
        Signature := SignedXml.GetXml();

        NamespaceMgr.AddNamespace('ns', SignatureNamespaceUriTok);
        Signature.SelectSingleNode('./ns:SignedInfo/ns:CanonicalizationMethod/@Algorithm', NamespaceMgr, Node);
        LibraryAssert.AreEqual(C14NTransformUriTok, Node.AsXmlAttribute().Value, 'Incorrect canonicalization method was applied.');

        Signature.SelectSingleNode('./ns:SignedInfo/ns:Reference/ns:Transforms/ns:Transform/@Algorithm', NamespaceMgr, Node);
        LibraryAssert.AreEqual(C14NTransformUriTok, Node.AsXmlAttribute().Value, 'Incorrect transform was applied.');
    end;

    [Test]
    procedure SignXmlDocumentWithSigningKeyAsSecretText()
    var
        XmlToSign: XmlDocument;
        SignedXmlElement: XmlElement;
        SigningKey: SecretText;
    begin
        XmlDocument.ReadFrom('<TestXml Id="ID01">XML to sign</TestXml>', XmlToSign);
        SignedXml.InitializeSignedXml(XmlToSign);

        GetSignatureKeyXmlString(SigningKey);
        SignedXml.SetSigningKey(SigningKey);
        SignedXml.InitializeReference('#ID01');

        SignedXml.ComputeSignature();

        SignedXmlElement := SignedXml.GetXml();
        LibraryAssert.AreEqual('Signature', SignedXmlElement.LocalName, 'Signature was not computed.');
    end;

    [Test]
    procedure SignXmlDocumentWithSigningKeyAsSecretTextAndRsaAlgorithm()
    var
        XmlToSign: XmlDocument;
        SignedXmlElement: XmlElement;
        SigningKey: SecretText;
    begin
        XmlDocument.ReadFrom('<TestXml Id="ID01">XML to sign</TestXml>', XmlToSign);
        SignedXml.InitializeSignedXml(XmlToSign);

        GetSignatureKeyXmlString(SigningKey);
        SignedXml.SetSigningKey(SigningKey, Enum::SignatureAlgorithm::RSA);
        SignedXml.InitializeReference('#ID01');

        SignedXml.ComputeSignature();

        SignedXmlElement := SignedXml.GetXml();
        LibraryAssert.AreEqual('Signature', SignedXmlElement.LocalName, 'Signature was not computed.');
    end;

    [Test]
    procedure SignXmlDocumentAddKeyInfoInSignature()
    var
        SignatureKey: Codeunit "Signature Key";
        XmlDoc: XmlDocument;
        DataElement: XmlElement;
        PrivateKey: SecretText;
        CertPassword: SecretText;
        Signature: XmlElement;
        NamespaceMgr: XmlNamespaceManager;
        KeyInfoNode: XmlNode;
    begin
        // [SCENARIO] SignedXml can generate signature with X509Data node according to W3C XML Signature Syntax

        // [GIVEN] Prepare XML document for signing
        XmlDocument.ReadFrom('<Data Id="Id12345">XML element to sign</Data>', XmlDoc);
        XmlDoc.GetRoot(DataElement);
        SignedXml.InitializeSignedXml(DataElement);
        
        // [GIVEN] Set signing key on the SignedXml instance
        GetSignatureKeyXmlString(PrivateKey);
        SignatureKey.FromXmlString(PrivateKey);
        SignedXml.SetSigningKey(SignatureKey);

        // [GIVEN] Add the signed element reference
        SignedXml.InitializeReference('#Id12345');
        SignedXml.AddReferenceToSignedXML();

        SignedXml.InitializeKeyInfo();

        // [WHEN] Add a key info clause from the X509 certificate and generate signature
        SignedXml.AddKeyInfoClauseFromX509Certificate(GetCertificateData(), CertPassword);
        SignedXml.ComputeSignature();

        // [THEN] The signature contains the X509Data element
        Signature := SignedXml.GetXml();
        NamespaceMgr.AddNamespace('ns', 'http://www.w3.org/2000/09/xmldsig#');
        LibraryAssert.IsTrue(Signature.SelectSingleNode('./ns:KeyInfo/ns:X509Data/ns:X509Certificate', NamespaceMgr, KeyInfoNode), 'The XML signature must contain the X509Data element.');
    end;

    local procedure GetSignatureElement(SignedXmlDocument: XmlDocument; var SignatureElement: XmlElement)
    var
        NSMgr: XmlNamespaceManager;
        SignatureNode: XmlNode;
    begin
        NSMgr.NameTable(SignedXmlDocument.NameTable());
        NSMgr.AddNamespace('dsig', 'http://www.w3.org/2000/09/xmldsig#');

        SignedXmlDocument.SelectSingleNode('//dsig:Signature', NSMgr, SignatureNode);

        SignatureElement := SignatureNode.AsXmlElement();
    end;

    local procedure GetValidSignedXml(var SignedXmlDocument: XmlDocument)
    var
        XmlReadOptions: XmlReadOptions;
    begin
        XmlReadOptions.PreserveWhitespace := true;

        XmlDocument.ReadFrom(
            '<Data xmlns="http://www.example.com/data">' +
            '<Item>' +
            '<No>1</No>' +
            '<Description>A</Description>' +
            '</Item>' +
            '<Item>' +
            '<No>2</No>' +
            '<Description>B</Description>' +
            '</Item>' +
            '<Signature xmlns="http://www.w3.org/2000/09/xmldsig#">' +
            '<SignedInfo><CanonicalizationMethod Algorithm="http://www.w3.org/TR/2001/REC-xml-c14n-20010315" />' +
            '<SignatureMethod Algorithm="http://www.w3.org/2001/04/xmldsig-more#rsa-sha256" />' +
            '<Reference URI="">' +
            '<Transforms>' +
            '<Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature" />' +
            '</Transforms>' +
            '<DigestMethod Algorithm="http://www.w3.org/2001/04/xmlenc#sha256" />' +
            '<DigestValue>R1TlSCUFGs6DIIp3I/W5ztsYNv4Y2AD8IGkpTAUt6NI=</DigestValue>' +
            '</Reference>' +
            '</SignedInfo>' +
            '<SignatureValue>ID0agWZ8wIeuak7XcgKEVtmuKYQGAU2dd4HDElKFCm1pLtoLybW21S6LyDmUwxSou4gaXmYBNbkG787EeQRXC7MDyfo4vygh0jryPSrvxxjE9oPktf0hqou7Dx+wB6rc+chxDOysflPSGwfvtBZl7tgcgT7DOqj3Xr4kn4vJ1gw=</SignatureValue>' +
            '<KeyInfo>' +
            '<KeyValue>' +
            '<RSAKeyValue>' +
            '<Modulus>xgEGvHk+U/RY0j9l3MP7o+S2a6uf4XaRBhu1ztdCHz8tMG8Kj4/qJmgsSZQD17sRctHGBTUJWp4CLtBwCf0zAGVzySwUkcHSu1/2mZ/w7Nr0TQHKeWr/j8pvXH534DKEvugr21DAHbi4c654eLUL+JW/wJJYqJh7qHM3W3Fh7ys=</Modulus>' +
            '<Exponent>AQAB</Exponent>' +
            '</RSAKeyValue>' +
            '</KeyValue>' +
            '</KeyInfo>' +
            '</Signature>' +
            '</Data>',
            XmlReadOptions,
            SignedXmlDocument);
    end;

    local procedure GetInvalidSignedXml(var SignedXmlDocument: XmlDocument)
    var
        XmlReadOptions: XmlReadOptions;
    begin
        XmlReadOptions.PreserveWhitespace := true;

        XmlDocument.ReadFrom(
            '<Data xmlns="http://www.example.com/data">' +
            '<Item>' +
            '<No>1</No>' +
            '<Description>A</Description>' +
            '</Item>' +
            '<Signature xmlns="http://www.w3.org/2000/09/xmldsig#">' +
            '<SignedInfo><CanonicalizationMethod Algorithm="http://www.w3.org/TR/2001/REC-xml-c14n-20010315" />' +
            '<SignatureMethod Algorithm="http://www.w3.org/2001/04/xmldsig-more#rsa-sha256" />' +
            '<Reference URI="">' +
            '<Transforms>' +
            '<Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature" />' +
            '</Transforms>' +
            '<DigestMethod Algorithm="http://www.w3.org/2001/04/xmlenc#sha256" />' +
            '<DigestValue>R1TlSCUFGs6DIIp3I/W5ztsYNv4Y2AD8IGkpTAUt6NI=</DigestValue>' +
            '</Reference>' +
            '</SignedInfo>' +
            '<SignatureValue>ID0agWZ8wIeuak7XcgKEVtmuKYQGAU2dd4HDElKFCm1pLtoLybW21S6LyDmUwxSou4gaXmYBNbkG787EeQRXC7MDyfo4vygh0jryPSrvxxjE9oPktf0hqou7Dx+wB6rc+chxDOysflPSGwfvtBZl7tgcgT7DOqj3Xr4kn4vJ1gw=</SignatureValue>' +
            '<KeyInfo>' +
            '<KeyValue>' +
            '<RSAKeyValue>' +
            '<Modulus>xgEGvHk+U/RY0j9l3MP7o+S2a6uf4XaRBhu1ztdCHz8tMG8Kj4/qJmgsSZQD17sRctHGBTUJWp4CLtBwCf0zAGVzySwUkcHSu1/2mZ/w7Nr0TQHKeWr/j8pvXH534DKEvugr21DAHbi4c654eLUL+JW/wJJYqJh7qHM3W3Fh7ys=</Modulus>' +
            '<Exponent>AQAB</Exponent>' +
            '</RSAKeyValue>' +
            '</KeyValue>' +
            '</KeyInfo>' +
            '</Signature>' +
            '</Data>',
            XmlReadOptions,
            SignedXmlDocument);
    end;

    local procedure GetSignatureKeyXmlString(var SecretXmlString: SecretText)
    var
        XmlString: Text;
    begin
        XmlString :=
            '<RSAKeyValue>' +
            '<Modulus>xgEGvHk+U/RY0j9l3MP7o+S2a6uf4XaRBhu1ztdCHz8tMG8Kj4/qJmgsSZQD17sRctHGBTUJWp4CLtBwCf0zAGVzySwUkcHSu1/2mZ/w7Nr0TQHKeWr/j8pvXH534DKEvugr21DAHbi4c654eLUL+JW/wJJYqJh7qHM3W3Fh7ys=</Modulus>' +
            '<Exponent>AQAB</Exponent>' +
            '<P>/KDieObcq+Os3DgLemqOz3n1S4luULvj8X6B5mZg1dlEKnjOV7WYODve1QUroDrN/qriHQAui6LWJf+jfhOMtw==</P>' +
            '<Q>yKWD2JNCrAgtjk2bfF1HYt24tq8+q7x2ek3/cUhqwInkrZqOFokex3+yBB879TuUOadvBXndgMHHcJQKSAJlLQ==</Q>' +
            '<DP>XRuGnHyptAhTe06EnHeNbtZKG67pI4Q8PJMdmSb+ZZKP1v9zPUxGb+NQ+z3OmF1T8ppUf8/DV9+KAbM4NI1L/Q==</DP>' +
            '<DQ>dGBsBKYFObrUkYE5+fwwd4uao3sponqBTZcH3jDemiZg2MCYQUHu9E+AdRuYrziLVJVks4xniVLb1tRG0lVxUQ==</DQ>' +
            '<InverseQ>SfjdGT81HDJSzTseigrM+JnBKPPrzpeEp0RbTP52Lm23YARjLCwmPMMdAwYZsvqeTuHEDQcOHxLHWuyN/zgP2A==</InverseQ>' +
            '<D>XzxrIwgmBHeIqUe5FOBnDsOZQlyAQA+pXYjCf8Rll2XptFwUdkzAUMzWUGWTG5ZspA9l8Wc7IozRe/bhjMxuVK5yZhPDKbjqRdWICA95Jd7fxlIirHOVMQRdzI7xNKqMNQN05MLJfsEHUYtOLhZE+tfhJTJnnmB7TMwnJgc4O5E=</D>' +
            '</RSAKeyValue>';
        SecretXmlString := XmlString;
    end;

    local procedure GetCertificateData(): Text
    begin
        exit(
            'MIICVjCCAb8CAg37MA0GCSqGSIb3DQEBBQUAMIGbMQswCQYDVQQGEwJKUDEOMAwG' +
            'A1UECBMFVG9reW8xEDAOBgNVBAcTB0NodW8ta3UxETAPBgNVBAoTCEZyYW5rNERE' +
            'MRgwFgYDVQQLEw9XZWJDZXJ0IFN1cHBvcnQxGDAWBgNVBAMTD0ZyYW5rNEREIFdl' +
            'YiBDQTEjMCEGCSqGSIb3DQEJARYUc3VwcG9ydEBmcmFuazRkZC5jb20wHhcNMTIw' +
            'ODIyMDUyNzIzWhcNMTcwODIxMDUyNzIzWjBKMQswCQYDVQQGEwJKUDEOMAwGA1UE' +
            'CAwFVG9reW8xETAPBgNVBAoMCEZyYW5rNEREMRgwFgYDVQQDDA93d3cuZXhhbXBs' +
            'ZS5jb20wgZ8wDQYJKoZIhvcNAQEBBQADgY0AMIGJAoGBAMYBBrx5PlP0WNI/ZdzD' +
            '+6Pktmurn+F2kQYbtc7XQh8/LTBvCo+P6iZoLEmUA9e7EXLRxgU1CVqeAi7QcAn9' +
            'MwBlc8ksFJHB0rtf9pmf8Oza9E0Bynlq/4/Kb1x+d+AyhL7oK9tQwB24uHOueHi1' +
            'C/iVv8CSWKiYe6hzN1txYe8rAgMBAAEwDQYJKoZIhvcNAQEFBQADgYEAASPdjigJ' +
            'kXCqKWpnZ/Oc75EUcMi6HztaW8abUMlYXPIgkV2F7YanHOB7K4f7OOLjiz8DTPFf' +
            'jC9UeuErhaA/zzWi8ewMTFZW/WshOrm3fNvcMrMLKtH534JKvcdMg6qIdjTFINIr' +
            'evnAhf0cwULaebn+lMs8Pdl7y37+sfluVok=');
    end;
}