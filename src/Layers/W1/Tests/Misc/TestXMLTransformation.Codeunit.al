codeunit 139149 "Test XML Transformation"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [UT] [XML Transformation]
    end;

    var
        Assert: Codeunit Assert;
        FunctionCallFailedErr: Label 'Function call failed.';
        FunctionCallNotFailedErr: Label 'Function call not failed.';
        XMLTransformErr: Label 'The XML cannot be transformed.';

    [Test]
    [Scope('OnPrem')]
    procedure TestXMLTransformationStream()
    var
        TempBlobXML: Codeunit "Temp Blob";
        TempBlobXSLT: Codeunit "Temp Blob";
        XMLDOMMgt: Codeunit "XML DOM Management";
        XmlDocument: DotNet XmlDocument;
        ExpectedXmlDocument: DotNet XmlDocument;
        XMLInStream: InStream;
        XSLTInStream: InStream;
        XMLOutStream: OutStream;
        XSLTOutStream: OutStream;
    begin
        // [SCENARIO 227334] XML file can be transformed to another XML using XSLT stylesheet

        // [GIVEN] Incoming XML document InStream
        TempBlobXML.CreateOutStream(XMLOutStream, TEXTENCODING::UTF8);
        XMLOutStream.WriteText(CreateIncomingPersonsXMLText());
        TempBlobXML.CreateInStream(XMLInStream);

        // [GIVEN] XSLT stylesheet InStream
        TempBlobXSLT.CreateOutStream(XSLTOutStream, TEXTENCODING::UTF8);
        XSLTOutStream.WriteText(CreateTransformationSchemaPersonsText());
        TempBlobXSLT.CreateInStream(XSLTInStream);

        // [WHEN] Function TransformXML is being run
        CreateOutStream(XMLOutStream);
        Assert.IsTrue(XMLDOMMgt.TryTransformXMLToOutStream(XMLInStream, XSLTInStream, XMLOutStream), FunctionCallFailedErr);

        // [THEN] Resulting XML has expected structure and content
        XMLDOMMgt.LoadXMLDocumentFromOutStream(XMLOutStream, XmlDocument);
        CreateExpectedXMLDoc(ExpectedXmlDocument);
        VerifyTransformedXMLContent(XmlDocument, ExpectedXmlDocument);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestBrokenXMLTransformationStream()
    var
        TempBlobXML: Codeunit "Temp Blob";
        TempBlobXSLT: Codeunit "Temp Blob";
        XMLDOMMgt: Codeunit "XML DOM Management";
        XMLInStream: InStream;
        XSLTInStream: InStream;
        XMLOutStream: OutStream;
        XSLTOutStream: OutStream;
    begin
        // [SCENARIO 227334] Broken XML InStream transformation leads to error

        // [GIVEN] Broken incoming XML document InStream
        TempBlobXML.CreateOutStream(XMLOutStream, TEXTENCODING::UTF8);
        XMLOutStream.WriteText(CreateBrokenXMLText());
        TempBlobXML.CreateInStream(XMLInStream);

        // [GIVEN] XSLT stylesheet InStream
        TempBlobXSLT.CreateOutStream(XSLTOutStream, TEXTENCODING::UTF8);
        XSLTOutStream.WriteText(CreateTransformationSchemaPersonsText());
        TempBlobXSLT.CreateInStream(XSLTInStream);

        // [WHEN] Function TransformXML is being run
        CreateOutStream(XMLOutStream);
        Assert.IsFalse(XMLDOMMgt.TryTransformXMLToOutStream(XMLInStream, XSLTInStream, XMLOutStream), FunctionCallNotFailedErr);

        // [THEN] Function failed with error
        Assert.ExpectedError('System.Xml.XmlDocument.Load failed');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestBrokenXSLTransformationStream()
    var
        TempBlobXML: Codeunit "Temp Blob";
        TempBlobXSLT: Codeunit "Temp Blob";
        XMLDOMMgt: Codeunit "XML DOM Management";
        XMLInStream: InStream;
        XSLTInStream: InStream;
        XMLOutStream: OutStream;
        XSLTOutStream: OutStream;
    begin
        // [SCENARIO 227334] Broken XSL InStream transformation leads to error

        // [GIVEN] Incoming XML document InStream
        TempBlobXML.CreateOutStream(XMLOutStream, TEXTENCODING::UTF8);
        XMLOutStream.WriteText(CreateIncomingPersonsXMLText());
        TempBlobXML.CreateInStream(XMLInStream);

        // [GIVEN] Broken XSLT stylesheet InStream
        TempBlobXSLT.CreateOutStream(XSLTOutStream, TEXTENCODING::UTF8);
        XSLTOutStream.WriteText(CreateBrokenXMLText());
        TempBlobXSLT.CreateInStream(XSLTInStream);

        // [WHEN] Function TransformXML is being run
        CreateOutStream(XMLOutStream);
        Assert.IsFalse(XMLDOMMgt.TryTransformXMLToOutStream(XMLInStream, XSLTInStream, XMLOutStream), FunctionCallNotFailedErr);

        // [THEN] Function failed with error
        Assert.ExpectedError('System.Xml.Xsl.XslCompiledTransform.Load failed');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestHTMLTransformationStream()
    var
        TempBlobXML: Codeunit "Temp Blob";
        TempBlobXSLT: Codeunit "Temp Blob";
        XMLDOMMgt: Codeunit "XML DOM Management";
        XmlDocument: DotNet XmlDocument;
        ExpectedXmlDocument: DotNet XmlDocument;
        XMLInStream: InStream;
        XSLTInStream: InStream;
        XMLOutStream: OutStream;
    begin
        // [SCENARIO 227334] XML file can be transformed to HTML using XSLT stylesheet

        // [GIVEN] Incoming XML document InStream
        CreateIncomingXMLBlobCDCatalog(TempBlobXML);
        TempBlobXML.CreateInStream(XMLInStream);

        // [GIVEN] XSLT stylesheet InStream
        CreateTransformationSchemaBlobCDCatalog(TempBlobXSLT);
        TempBlobXSLT.CreateInStream(XSLTInStream);

        // [WHEN] Function TransformXML is being run
        CreateOutStream(XMLOutStream);
        Assert.IsTrue(XMLDOMMgt.TryTransformXMLToOutStream(XMLInStream, XSLTInStream, XMLOutStream), FunctionCallFailedErr);

        // [THEN] Resulting HTML has expected structure and content
        XMLDOMMgt.LoadXMLDocumentFromOutStream(XMLOutStream, XmlDocument);
        CreateExpectedHTMLDoc(ExpectedXmlDocument);
        VerifyTransformedXMLContent(XmlDocument, ExpectedXmlDocument);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestXMLTransformationText()
    var
        XMLDOMMgt: Codeunit "XML DOM Management";
        XmlDocument: DotNet XmlDocument;
        ExpectedXmlDocument: DotNet XmlDocument;
        XMLText: Text;
        TransformationSchema: Text;
        TransformedXMLText: Text;
    begin
        // [SCENARIO 227334] XML file can be transformed to another XML using XSLT stylesheet

        // [GIVEN] Incoming XML document text
        XMLText := CreateIncomingPersonsXMLText();

        // [GIVEN] XSLT stylesheet text
        TransformationSchema := CreateTransformationSchemaPersonsText();

        // [WHEN] Function TransformXMLText is being run
        TransformedXMLText := XMLDOMMgt.TransformXMLText(XMLText, TransformationSchema);

        // [THEN] Resulting XML has expected structure and content
        XMLDOMMgt.LoadXMLDocumentFromText(TransformedXMLText, XmlDocument);
        CreateExpectedXMLDoc(ExpectedXmlDocument);
        VerifyTransformedXMLContent(XmlDocument, ExpectedXmlDocument);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestBrokenXMLTransformationText()
    var
        XMLDOMMgt: Codeunit "XML DOM Management";
        XMLText: Text;
        TransformationSchema: Text;
    begin
        // [SCENARIO 227334] Broken XML text transformation leads to error

        // [GIVEN] Broken XML document text
        XMLText := CreateBrokenXMLText();

        // [GIVEN] XSLT stylesheet text
        TransformationSchema := CreateTransformationSchemaPersonsText();

        // [WHEN] Function TransformXMLText is being run
        asserterror XMLDOMMgt.TransformXMLText(XMLText, TransformationSchema);

        // [THEN] Function failed with error
        Assert.ExpectedError(XMLTransformErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestBrokenXSLTransformationText()
    var
        XMLDOMMgt: Codeunit "XML DOM Management";
        XMLText: Text;
        TransformationSchema: Text;
    begin
        // [SCENARIO 227334] Broken XSL text transformation leads to error

        // [GIVEN] Incoming XML document text
        XMLText := CreateIncomingPersonsXMLText();

        // [GIVEN] Broken XSLT stylesheet text
        TransformationSchema := CreateBrokenXMLText();

        // [WHEN] Function TransformXMLText is being run
        asserterror XMLDOMMgt.TransformXMLText(XMLText, TransformationSchema);

        // [THEN] Function failed with error
        Assert.ExpectedError(XMLTransformErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FormatXML()
    var
        XMLDOMMgt: Codeunit "XML DOM Management";
        XMLText: Text;
        FormattedXMLText: Text;
    begin
        // [SCENARIO 229439] "On-line-string" XML can be formatted with new lines and identation with function TryFormatXML

        // [GIVEN] "On-line-string" XML
        XMLText := CreateOneLineXMLText();

        // [WHEN] XMLDOMMgt.TryFormatXML is being run
        Assert.IsTrue(XMLDOMMgt.TryFormatXML(XMLText, FormattedXMLText), FunctionCallFailedErr);

        // [THEN] XML text contains new lines and identation
        VerifyXMLText(FormattedXMLText, CreateExpectedFormattedXMLText());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FormatBrokenXML()
    var
        XMLDOMMgt: Codeunit "XML DOM Management";
        XMLText: Text;
        FormattedXMLText: Text;
    begin
        // [SCENARIO 229439] Try to format broken XML leads to error

        // [GIVEN] Broken XML
        XMLText := CreateBrokenXMLText();

        // [WHEN] XMLDOMMgt.TryFormatXML is being run
        Assert.IsFalse(XMLDOMMgt.TryFormatXML(XMLText, FormattedXMLText), FunctionCallNotFailedErr);

        // [THEN] Function failed with error
        Assert.ExpectedError('System.Xml.Linq.XDocument.Parse failed');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RemoveXMLNameSpaces()
    var
        XMLDOMMgt: Codeunit "XML DOM Management";
        XMLText: Text;
        SimplifiedXMLText: Text;
    begin
        // [SCENARIO 229439] XML containing namespaces can be transformed to simplified form - without namespaces

        // [GIVEN] XML text with namespaces
        XMLText := CreateXMLWithNamespacesText();

        // [WHEN] Function XMLDOMMgt.RemoveNameSpaces is being run
        SimplifiedXMLText := XMLDOMMgt.RemoveNamespaces(XMLText);

        // [THEN] Resulted XML does not contain namespaces
        VerifyXMLText(SimplifiedXMLText, CreateExpectedSimplifiedXMLText());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RemoveNameSpacesBrokenXML()
    var
        XMLDOMMgt: Codeunit "XML DOM Management";
        XMLText: Text;
    begin
        // [SCENARIO 229439] Removing namespaces from broken XML leads to error

        // [GIVEN] Broken XML
        XMLText := CreateBrokenXMLText();

        // [WHEN] Function XMLDOMMgt.RemoveNameSpaces is being run
        asserterror XMLDOMMgt.RemoveNamespaces(XMLText);

        // [THEN] Function failed with error
        Assert.ExpectedError(XMLTransformErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetJsonStructureJsonToXMLCreateDefaultRootNoEndlessLoop()
    var
        TempBlob: Codeunit "Temp Blob";
        GetJsonStructure: Codeunit "Get Json Structure";
        InStr: InStream;
        OutStr: OutStream;
        Utf8Text: Label '{ ''name'': ''日本語テスト'' }';
        RootText: Label 'root';
        NameText: Label 'name';
        OutputText: Text;
    begin
        // [SCENARIO 400994] Get Json Structure "JsonToXMLCreateDefaultRoot" should correctly process UTF8 text
        // [GIVEN] Blob with text '{ ''name'': ''日本語テスト'' }'
        TempBlob.CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.Write(Utf8Text);
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        TempBlob.CreateOutStream(OutStr, TextEncoding::UTF8);

        // [WHEN] Get Json Structure "JsonToXMLCreateDefaultRoot" method is invoked with Blob InStream as input parameter
        GetJsonStructure.JsonToXMLCreateDefaultRoot(InStr, OutStr);

        // [THEN] No infinite loop happens and output contains 'root' and 'name' substrings
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        InStr.Read(OutputText);
        Assert.IsSubstring(OutputText, NameText);
        Assert.IsSubstring(OutputText, RootText);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetJsonStructureJsonToXMLNoEndlessLoop()
    var
        TempBlob: Codeunit "Temp Blob";
        GetJsonStructure: Codeunit "Get Json Structure";
        InStr: InStream;
        OutStr: OutStream;
        Utf8Text: Label '{ ''name'': ''日本語テスト'' }';
        NameText: Label 'name';
        OutputText: Text;
    begin
        // [SCENARIO 400994] Get Json Structure "JsonToXML" method should correctly process UTF8 text
        // [GIVEN] Blob with text '{ ''name'': ''日本語テスト'' }'
        TempBlob.CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.Write(Utf8Text);
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        TempBlob.CreateOutStream(OutStr, TextEncoding::UTF8);

        // [WHEN] Get Json Structure "JsonToXML" method is invoked with Blob InStream as input parameter
        GetJsonStructure.JsonToXML(InStr, OutStr);

        // [THEN] No infinite loop happens and output contains 'name' substring
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        InStr.Read(OutputText);
        Assert.IsSubstring(OutputText, NameText);
    end;

    local procedure CreateBrokenXMLText(): Text
    begin
        exit(Format(CreateGuid()));
    end;

    local procedure CreateOutStream(var OutStr: OutStream)
    var
        TempBlob: Codeunit "Temp Blob";
    begin
        TempBlob.CreateOutStream(OutStr);
    end;

    local procedure CreateIncomingPersonsXMLText(): Text
    begin
        exit(
          '<?xml version="1.0" encoding="UTF-8"?>' +
          '<persons>' +
          '<person username="MP123456">' +
          '<name>Ester</name>' +
          '<surname>Henderson</surname>' +
          '</person>' +
          '<person username="PK123456">' +
          '<name>Benjamin</name>' +
          '<surname>Chiu</surname>' +
          '</person>' +
          '</persons>');
    end;

    local procedure CreateIncomingXMLBlobCDCatalog(var TempBlob: Codeunit "Temp Blob")
    var
        OutStr: OutStream;
    begin
        TempBlob.CreateOutStream(OutStr);

        OutStr.WriteText('<?xml version="1.0"?>');
        OutStr.WriteText('<catalog>');
        OutStr.WriteText('<cd>');
        OutStr.WriteText('<title>Empire Burlesque</title>');
        OutStr.WriteText('<artist>Bob Dylan</artist>');
        OutStr.WriteText('<country>USA</country>');
        OutStr.WriteText('<company>Colombia</company>');
        OutStr.WriteText('<price>10.90</price>');
        OutStr.WriteText('<year>1985</year>');
        OutStr.WriteText('</cd>');
        OutStr.WriteText('</catalog>');
    end;

    local procedure CreateExpectedXMLDoc(XmlDocument: DotNet XmlDocument)
    var
        XMLDOMMgt: Codeunit "XML DOM Management";
        XMLText: Text;
    begin
        XMLText := CreateOneLineXMLText();
        XMLDOMMgt.LoadXMLDocumentFromText(XMLText, XmlDocument);
    end;

    local procedure CreateExpectedHTMLDoc(XmlDocument: DotNet XmlDocument)
    var
        XMLDOMMgt: Codeunit "XML DOM Management";
        XMLText: Text;
    begin
        XMLText :=
          '<?xml version="1.0" encoding="utf-8"?>' +
          '<html>' +
          '<body>' +
          '<h2>My CD Collection</h2>' +
          '<table border="1">' +
          '<tr bgcolor="#9acd32">' +
          '<th>Title</th>' +
          '<th>Artist</th>' +
          '</tr>' +
          '<tr>' +
          '<td>Empire Burlesque</td>' +
          '<td>Bob Dylan</td>' +
          '</tr>' +
          '</table>' +
          '</body>' +
          '</html>';

        XMLDOMMgt.LoadXMLDocumentFromText(XMLText, XmlDocument);
    end;

    local procedure CreateExpectedFormattedXMLText(): Text
    var
        SystemEnvironment: DotNet SystemEnvironment;
    begin
        SystemEnvironment := SystemEnvironment.SystemEnvironment();
        exit(
          '<?xml version="1.0" encoding="utf-8"?>' + SystemEnvironment.NewLine() +
          '<transform>' + SystemEnvironment.NewLine() +
          '  <record>' + SystemEnvironment.NewLine() +
          '    <username>MP123456</username>' + SystemEnvironment.NewLine() +
          '    <fullname>Ester Henderson</fullname>' + SystemEnvironment.NewLine() +
          '  </record>' + SystemEnvironment.NewLine() +
          '  <record>' + SystemEnvironment.NewLine() +
          '    <username>PK123456</username>' + SystemEnvironment.NewLine() +
          '    <fullname>Benjamin Chiu</fullname>' + SystemEnvironment.NewLine() +
          '  </record>' + SystemEnvironment.NewLine() +
          '</transform>');
    end;

    local procedure CreateExpectedSimplifiedXMLText(): Text
    begin
        exit(
          '<?xml version="1.0" encoding="utf-8"?>' +
          '<student>' +
          '<id>3235329</id>' +
          '<name>Jeff Smith</name>' +
          '<language>C#</language>' +
          '<rating>9.5</rating>' +
          '</student>');
    end;

    local procedure CreateOneLineXMLText(): Text
    begin
        exit(
          '<?xml version="1.0" encoding="utf-8"?>' +
          '<transform>' +
          '<record>' +
          '<username>MP123456</username>' +
          '<fullname>Ester Henderson</fullname>' +
          '</record>' +
          '<record>' +
          '<username>PK123456</username>' +
          '<fullname>Benjamin Chiu</fullname>' +
          '</record>' +
          '</transform>');
    end;

    local procedure CreateXMLWithNamespacesText(): Text
    begin
        exit(
          '<?xml version="1.0" encoding="utf-8"?>' +
          '<d:student xmlns:d="http://www.develop.com/student" ' +
          'xmlns:i="urn:schemas-develop-com:identifiers" ' +
          'xmlns:p="urn:schemas-develop-com:programming-languages">' +
          '<i:id>3235329</i:id>' +
          '<name>Jeff Smith</name>' +
          '<p:language>C#</p:language>' +
          '<d:rating>9.5</d:rating>' +
          '</d:student>');
    end;

    local procedure CreateTransformationSchemaPersonsText(): Text
    begin
        exit(
          '<?xml version="1.0"?>' +
          '<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">' +
          '<xsl:output method="xml" indent="yes"/>' +
          '<xsl:template match="persons">' +
          '<transform>' +
          '<xsl:apply-templates/>' +
          '</transform>' +
          '</xsl:template>' +
          '<xsl:template match="person">' +
          '<record>' +
          '<xsl:apply-templates select="@*|*"/>' +
          '</record>' +
          '</xsl:template>' +
          '<xsl:template match="@username">' +
          '<username>' +
          '<xsl:value-of select="."/>' +
          '</username>' +
          '</xsl:template>' +
          '<xsl:template match="name">' +
          '<fullname>' +
          '<xsl:apply-templates/>' +
          '<xsl:apply-templates select="following-sibling::surname" mode="fullname"/>' +
          '</fullname>' +
          '</xsl:template>' +
          '<xsl:template match="surname"/>' +
          '<xsl:template match="surname" mode="fullname">' +
          '<xsl:text> </xsl:text>' +
          '<xsl:apply-templates/>' +
          '</xsl:template>' +
          '</xsl:stylesheet>');
    end;

    local procedure CreateTransformationSchemaBlobCDCatalog(var TempBlob: Codeunit "Temp Blob")
    var
        OutStr: OutStream;
    begin
        TempBlob.CreateOutStream(OutStr);

        OutStr.WriteText('<?xml version="1.0" encoding="UTF-8"?>');
        OutStr.WriteText('<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">');
        OutStr.WriteText('<xsl:output method="xml" indent="yes"/>');
        OutStr.WriteText('<xsl:template match="/">');
        OutStr.WriteText('<html>');
        OutStr.WriteText('<body>');
        OutStr.WriteText('<h2>My CD Collection</h2>');
        OutStr.WriteText('<table border="1">');
        OutStr.WriteText('<tr bgcolor="#9acd32">');
        OutStr.WriteText('<th>Title</th>');
        OutStr.WriteText('<th>Artist</th>');
        OutStr.WriteText('</tr>');
        OutStr.WriteText('<xsl:for-each select="catalog/cd">');
        OutStr.WriteText('<tr>');
        OutStr.WriteText('<td><xsl:value-of select="title"/></td>');
        OutStr.WriteText('<td><xsl:value-of select="artist"/></td>');
        OutStr.WriteText('</tr>');
        OutStr.WriteText('</xsl:for-each>');
        OutStr.WriteText('</table>');
        OutStr.WriteText('</body>');
        OutStr.WriteText('</html>');
        OutStr.WriteText('</xsl:template>');
        OutStr.WriteText('</xsl:stylesheet>');
    end;

    local procedure VerifyTransformedXMLContent(var XmlDocument: DotNet XmlDocument; var ExpectedXmlDocument: DotNet XmlDocument)
    begin
        Assert.AreEqual(ExpectedXmlDocument.InnerXml, XmlDocument.InnerXml, 'Invalid transformed XML');
    end;

    local procedure VerifyXMLText(ActualXMLText: Text; ExpectedXMLText: Text)
    begin
        Assert.AreEqual(ExpectedXMLText, ActualXMLText, 'Invalid XML Text');
    end;
}

