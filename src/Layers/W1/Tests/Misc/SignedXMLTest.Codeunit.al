codeunit 132559 "Signed XML Test"
{
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [XML] [Signed]
    end;

    var
        SignedXmlTextTestFailedErr: Label 'Xml Document Text signature test failed';
        SignedXmlStreamTestFailedErr: Label 'Xml Document Stream signature test failed';
        SignedXmlTextPITestFailedErr: Label 'Xml Document with processing instructions text signature test failed';
        SignedXmlStreamPITestFailedErr: Label 'Xml Document with processing instructions stream signature test failed';
        SignedXmlHardcodedTextTestFailedErr: Label 'Hardcoded Xml Document signature test failed';
        IncorrectSignedXmlTestFailedErr: Label 'Incorrect xml document signature test failed ';
        Assert: Codeunit Assert;
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";

    [Test]
    [Scope('OnPrem')]
    procedure TestSignedXmlText()
    var
        SignedXMLMgt: Codeunit "Signed XML Mgt.";
        Convert: DotNet Convert;
        RSAKey: DotNet RSACryptoServiceProvider;
        PrivateKey: Text;
        PublicKey: Text;
        XmlText: Text;
        SignedXmlText: Text;
    begin
        // [SCENARIO] Test of SignedXMLText function
        LibraryLowerPermissions.SetO365Basic();

        // [GIVEN] A private and public key
        RSAKey := RSAKey.RSACryptoServiceProvider();

        PrivateKey := Convert.ToBase64String(RSAKey.ExportCspBlob(true));
        PublicKey := Convert.ToBase64String(RSAKey.ExportCspBlob(false));

        // [GIVEN] A xml document in text representation
        XmlText := '<xml><data>something</data><data>another node</data></xml>';

        // [WHEN] The document is signed
        SignedXmlText := SignedXMLMgt.SignXmlText(XmlText, PrivateKey);

        // [THEN] The signature is valid
        Assert.IsTrue(SignedXMLMgt.CheckXmlTextSignature(SignedXmlText, PublicKey), SignedXmlTextTestFailedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSignedXmlStream()
    var
        TempBlob: Codeunit "Temp Blob";
        SignedXMLMgt: Codeunit "Signed XML Mgt.";
        OutStream: OutStream;
        InputStream: InStream;
        Convert: DotNet Convert;
        RSAKey: DotNet RSACryptoServiceProvider;
        PrivateKey: Text;
        PublicKey: Text;
        XmlText: Text;
        SignedXmlText: Text;
    begin
        // [SCENARIO] Test of SignedXMLStream function
        LibraryLowerPermissions.SetO365Basic();

        // [GIVEN] A private and public key
        RSAKey := RSAKey.RSACryptoServiceProvider();

        PrivateKey := Convert.ToBase64String(RSAKey.ExportCspBlob(true));
        PublicKey := Convert.ToBase64String(RSAKey.ExportCspBlob(false));

        // [GIVEN] A xml document in text representation
        XmlText := '<xml><data>something</data><data>another node</data></xml>';

        // [WHEN] The document is signed
        SignedXmlText := SignedXMLMgt.SignXmlText(XmlText, PrivateKey);

        TempBlob.CreateOutStream(OutStream, TEXTENCODING::Windows);
        OutStream.WriteText(SignedXmlText);
        TempBlob.CreateInStream(InputStream, TEXTENCODING::Windows);

        // [THEN] The signature is valid
        Assert.IsTrue(SignedXMLMgt.CheckXmlStreamSignature(InputStream, PublicKey), SignedXmlStreamTestFailedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSignedXmlTextWithProcIns()
    var
        SignedXMLMgt: Codeunit "Signed XML Mgt.";
        Convert: DotNet Convert;
        RSAKey: DotNet RSACryptoServiceProvider;
        PrivateKey: Text;
        PublicKey: Text;
        XmlText: Text;
        SignedXmlText: Text;
    begin
        // [SCENARIO] Test of SignedXMLText function on XmlDocument with processing instruction
        LibraryLowerPermissions.SetO365Basic();

        // [GIVEN] A private and public key
        RSAKey := RSAKey.RSACryptoServiceProvider();

        PrivateKey := Convert.ToBase64String(RSAKey.ExportCspBlob(true));
        PublicKey := Convert.ToBase64String(RSAKey.ExportCspBlob(false));

        // [GIVEN] A xml document in text representation
        XmlText := '<?xml version="1.0" encoding="UTF-8" ?>' +
          '<xml><data>something</data><data>another node</data></xml>';

        // [WHEN] The document is signed
        SignedXmlText := SignedXMLMgt.SignXmlText(XmlText, PrivateKey);

        // [THEN] The signature is valid
        Assert.IsTrue(SignedXMLMgt.CheckXmlTextSignature(SignedXmlText, PublicKey), SignedXmlTextPITestFailedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSignedXmlStreamWithProcIns()
    var
        TempBlob: Codeunit "Temp Blob";
        SignedXMLMgt: Codeunit "Signed XML Mgt.";
        OutStream: OutStream;
        InputStream: InStream;
        Convert: DotNet Convert;
        RSAKey: DotNet RSACryptoServiceProvider;
        PrivateKey: Text;
        PublicKey: Text;
        XmlText: Text;
        SignedXmlText: Text;
    begin
        // [SCENARIO] Test of SignedXMLStream function on XmlDocument with processing instruction
        LibraryLowerPermissions.SetO365Basic();

        // [GIVEN] A private and public key
        RSAKey := RSAKey.RSACryptoServiceProvider();

        PrivateKey := Convert.ToBase64String(RSAKey.ExportCspBlob(true));
        PublicKey := Convert.ToBase64String(RSAKey.ExportCspBlob(false));

        // [GIVEN] A xml document in text representation
        XmlText := '<?xml version="1.0" encoding="UTF-8" ?>' +
          '<xml><data>something</data><data>another node</data></xml>';

        // [WHEN] The document is signed
        SignedXmlText := SignedXMLMgt.SignXmlText(XmlText, PrivateKey);

        TempBlob.CreateOutStream(OutStream, TEXTENCODING::Windows);
        OutStream.WriteText(SignedXmlText);
        TempBlob.CreateInStream(InputStream, TEXTENCODING::Windows);

        // [THEN] The signature is valid
        Assert.IsTrue(SignedXMLMgt.CheckXmlStreamSignature(InputStream, PublicKey), SignedXmlStreamPITestFailedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestHardcodedValidXml()
    var
        SignedXMLMgt: Codeunit "Signed XML Mgt.";
        PublicKey: Text;
        SignedXmlText: Text;
    begin
        // [SCENARIO] Test valid hardcoded xml document and public key
        LibraryLowerPermissions.SetO365Basic();

        // [GIVEN] A signed xml document
        SignedXmlText := '<?xml version="1.0" encoding="UTF-8" ?>' +
          '<xml><data>something</data><data>another node</data>' +
          '<Signature xmlns="http://www.w3.org/2000/09/xmldsig#">' +
          '<SignedInfo><CanonicalizationMethod Algorithm="http://www.w3.org/TR/2001/REC-xml-c14n-20010315" />' +
          '<SignatureMethod Algorithm="http://www.w3.org/2000/09/xmldsig#rsa-sha1" /><Reference URI="">' +
          '<Transforms><Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature" />' +
          '</Transforms><DigestMethod Algorithm="http://www.w3.org/2000/09/xmldsig#sha1" />' +
          '<DigestValue>VhH7n9U2xFJSPDRmd1ssLb2kn9w=</DigestValue></Reference></SignedInfo>' +
          '<SignatureValue>PGxNsb7HfG9wtKMdzozJJ59Hdnf8Q+lVU65L6RW5qlju9ZhkUvjZMEGKAtFD38AgbR3sD' +
          'TMjyyY/5XriMZNDhE8NGOPOA7ZPoFVUkc1cCbvAFKmsxlz8zP3TBfrsL9jkBpdQi9rJKltAqI62NzPu/lkexb' +
          '6vPh9y5rPLZG7hH/g=</SignatureValue></Signature></xml>';

        // [GIVEN] A public key
        PublicKey := 'BgIAAACkAABSU0ExAAQAAAEAAQBr/IYd2end7HQ9Q9a7IH4uZhb6ICQ1Nqv4rbrW4ftOa96sHpMn4vPMfx9Nd2G4vN0RZLB' +
          'JzODADPyqwJmxwATD420PY5Tj8LUxBh60erCsxtc002551ggOxLAJFgfli3TtezAmT8uyoVj+SQ/wElfZqmMGADQVZ99QQt' +
          'N04lUOrA==';

        // [WHEN] The xml signature is validated
        // [THEN] The the xml is valid
        Assert.IsTrue(SignedXMLMgt.CheckXmlTextSignature(SignedXmlText, PublicKey), SignedXmlHardcodedTextTestFailedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestHardcodedInvalidXml()
    var
        SignedXMLMgt: Codeunit "Signed XML Mgt.";
        PublicKey: Text;
        SignedXmlText: Text;
    begin
        // [SCENARIO] Test invalid hardcoded xml document and public key
        LibraryLowerPermissions.SetO365Basic();

        // [GIVEN] A signed xml document
        SignedXmlText := '<?xml version="1.0" encoding="UTF-8" ?>' +
          '<xml><data>something different</data><data>another node</data>' +
          '<Signature xmlns="http://www.w3.org/2000/09/xmldsig#">' +
          '<SignedInfo><CanonicalizationMethod Algorithm="http://www.w3.org/TR/2001/REC-xml-c14n-20010315" />' +
          '<SignatureMethod Algorithm="http://www.w3.org/2000/09/xmldsig#rsa-sha1" /><Reference URI="">' +
          '<Transforms><Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature" />' +
          '</Transforms><DigestMethod Algorithm="http://www.w3.org/2000/09/xmldsig#sha1" />' +
          '<DigestValue>VhH7n9U2xFJSPDRmd1ssLb2kn9w=</DigestValue></Reference></SignedInfo>' +
          '<SignatureValue>PGxNsb7HfG9wtKMdzozJJ59Hdnf8Q+lVU65L6RW5qlju9ZhkUvjZMEGKAtFD38AgbR3sD' +
          'TMjyyY/5XriMZNDhE8NGOPOA7ZPoFVUkc1cCbvAFKmsxlz8zP3TBfrsL9jkBpdQi9rJKltAqI62NzPu/lkexb' +
          '6vPh9y5rPLZG7hH/g=</SignatureValue></Signature></xml>';

        // [GIVEN] A public key
        PublicKey := 'BgIAAACkAABSU0ExAAQAAAEAAQBr/IYd2end7HQ9Q9a7IH4uZhb6ICQ1Nqv4rbrW4ftOa96sHpMn4vPMfx9Nd2G4vN0RZLB' +
          'JzODADPyqwJmxwATD420PY5Tj8LUxBh60erCsxtc002551ggOxLAJFgfli3TtezAmT8uyoVj+SQ/wElfZqmMGADQVZ99QQt' +
          'N04lUOrA==';

        // [WHEN] The xml signature is validated
        // [THEN] The the xml is invalid
        Assert.IsFalse(SignedXMLMgt.CheckXmlTextSignature(SignedXmlText, PublicKey), IncorrectSignedXmlTestFailedErr);
    end;
}

