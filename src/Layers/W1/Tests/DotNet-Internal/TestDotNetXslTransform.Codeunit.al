codeunit 146038 Test_DotNet_XslTransform
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [DotNet] [UT] [XslTransform]
    end;

    var
        Assert: Codeunit Assert;
        DotNet_XslCompiledTransform: Codeunit DotNet_XslCompiledTransform;
        DotNet_XmlDocument: Codeunit DotNet_XmlDocument;
        XMLDOMManagement: Codeunit "XML DOM Management";

    [Scope('OnPrem')]
    procedure TransformXmlHelper(XsltTransformationText: Text; XmlData: Text): Text
    var
        TempBlob: Codeunit "Temp Blob";
        DotNet_XsltArgumentList: Codeunit DotNet_XsltArgumentList;
        TypeHelper: Codeunit "Type Helper";
        ResultStream: OutStream;
        OutStream: OutStream;
        InStream: InStream;
    begin
        TempBlob.CreateOutStream(OutStream, TEXTENCODING::UTF8);
        OutStream.WriteText(XsltTransformationText);

        Clear(DotNet_XslCompiledTransform);
        XMLDOMManagement.CreateXslTransformFromBlob(TempBlob, DotNet_XslCompiledTransform);
        LoadXmlDocumentHelper(XmlData);
        Clear(TempBlob);
        TempBlob.CreateOutStream(ResultStream, TEXTENCODING::UTF8);
        DotNet_XslCompiledTransform.Transform(DotNet_XmlDocument, DotNet_XsltArgumentList, ResultStream);
        TempBlob.CreateInStream(InStream, TEXTENCODING::UTF8);
        exit(TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.CRLFSeparator()));
    end;

    [Scope('OnPrem')]
    procedure LoadXmlDocumentHelper(XmlAsText: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        InputStream: InStream;
        OutStream: OutStream;
    begin
        TempBlob.CreateOutStream(OutStream, TEXTENCODING::UTF8);
        OutStream.WriteText(XmlAsText);
        TempBlob.CreateInStream(InputStream);
        DotNet_XmlDocument.InitXmlDocument();
        DotNet_XmlDocument.Load(InputStream);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure XmlSimpleTransformationToText()
    var
        XmlData: Text;
        Xslt: Text;
        ExpectedResult: Text;
        Result: Text;
    begin
        // [Given] Xslt tranformation:
        Xslt :=
          '<?xml version="1.0" encoding="UTF-8"?>' +
          '<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">' +
          '<xsl:output method="text" encoding="UTF-8" omit-xml-declaration="yes"/>' +
          '<xsl:template match="/">' +
          '  <xsl:value-of select="catalog/cd/title"/> - <xsl:value-of select="catalog/cd/artist"/>' +
          '</xsl:template>' +
          '</xsl:stylesheet>';

        // [WHEN] The following xml data is provided:
        XmlData :=
          '<?xml version="1.0" encoding="UTF-8"?>' +
          '<catalog>' +
          '  <cd>' +
          '    <title>Empire Burlesque</title>' +
          '    <artist>Bob Dylan</artist>' +
          '  </cd>' +
          '</catalog>';

        // [THEN] expected result is:
        ExpectedResult := 'Empire Burlesque - Bob Dylan';
        Result := TransformXmlHelper(Xslt, XmlData);
        Assert.AreEqual(ExpectedResult, Result, 'Simple Xml transformation fails');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure XmlSimpleTransformationToXml()
    var
        XmlData: Text;
        Xslt: Text;
        ExpectedResult: Text;
        Result: Text;
    begin
        // [Given] Xslt tranformation:
        Xslt :=
          '<?xml version="1.0" encoding="UTF-8"?>' +
          '<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">' +
          '<xsl:output method="xml" encoding="UTF-8" omit-xml-declaration="yes"/>' +
          '<xsl:template match="/">' +
          '<test><title><xsl:value-of select="catalog/cd/title"/></title></test>' +
          '</xsl:template>' +
          '</xsl:stylesheet>';

        // [WHEN] The following xml data is provided:
        XmlData := '<?xml version="1.0" encoding="UTF-8"?>' +
          '<catalog>' +
          '  <cd>' +
          '    <title>Empire Burlesque</title>' +
          '    <artist>Bob Dylan</artist>' +
          '  </cd>' +
          '</catalog>';

        // [THEN] expected result is:
        ExpectedResult := '<test><title>Empire Burlesque</title></test>';
        Result := TransformXmlHelper(Xslt, XmlData);
        LoadXmlDocumentHelper(Result);
        Result := DotNet_XmlDocument.OuterXml();
        Assert.AreEqual(ExpectedResult, Result, 'Simple Xml transformation fails');
    end;
}

