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

    [Test]
    [Scope('OnPrem')]
    procedure TestHTMLTransformationStream()
    var
        TempBlobXML: Codeunit "Temp Blob";
        TempBlobXSLT: Codeunit "Temp Blob";
        TempBlobResult: Codeunit "Temp Blob";
        XmlUtilities: Codeunit "XML Utilities";
        XMLInStream: InStream;
        XSLTInStream: InStream;
        XMLOutStream: OutStream;
        TransformedXMLText: Text;
    begin
        // [SCENARIO 227334] XML file can be transformed to HTML using XSLT stylesheet

        // [GIVEN] Incoming XML document InStream
        CreateIncomingXMLBlobCDCatalog(TempBlobXML);
        TempBlobXML.CreateInStream(XMLInStream);

        // [GIVEN] XSLT stylesheet InStream
        CreateTransformationSchemaBlobCDCatalog(TempBlobXSLT);
        TempBlobXSLT.CreateInStream(XSLTInStream);

        // [WHEN] Function TryTransformXmlToOutStream is being run
        TempBlobResult.CreateOutStream(XMLOutStream);
        Assert.IsTrue(XmlUtilities.TryTransformXmlToOutStream(XMLInStream, XSLTInStream, XMLOutStream), FunctionCallFailedErr);

        // [THEN] Resulting HTML has expected structure and content
        Assert.IsTrue(XmlUtilities.TryGetXmlAsText(TempBlobResult.CreateInStream(), TransformedXMLText), FunctionCallFailedErr);
        Assert.AreEqual(CreateExpectedHTMLText(), TransformedXMLText, 'Invalid transformed XML');
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

    local procedure CreateExpectedHTMLText(): Text
    begin
        exit(
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
          '</html>');
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
}
