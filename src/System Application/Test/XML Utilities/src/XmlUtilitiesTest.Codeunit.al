// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Xml;

using System.TestLibraries.Utilities;
using System.Utilities;
using System.Xml;

codeunit 130032 "XML Utilities Test"
{
    Subtype = Test;

    var
        Assert: Codeunit "Library Assert";
        XmlUtilities: Codeunit "XML Utilities";
        XmlTransformErr: Label 'The XML cannot be transformed.';
        EmptyStreamErr: Label 'The stream is empty.';
        NodePathErr: Label 'Node path cannot be empty.';
        BasePathErr: Label 'Base path cannot be empty.';
        InvalidNameTok: Label '1 <>,./\+-&()%:=? A  B''`[]!_', Locked = true;

    [Test]
    procedure XmlEscapeReplacesReservedCharacters()
    begin
        Assert.AreEqual('&lt;a href="x"&gt;Tom &amp; ''Jerry''&lt;/a&gt;', XmlUtilities.XmlEscape('<a href="x">Tom & ''Jerry''</a>'), 'Reserved characters must be escaped.');
    end;

    [Test]
    procedure XmlEscapeKeepsWhitespaceAndReplacesControlCharacters()
    var
        InputText: Text;
    begin
        InputText := 'a' + CharToText(9) + 'b' + CharToText(10) + 'c' + CharToText(13) + 'd' + CharToText(1) + 'e' + CharToText(31);
        Assert.AreEqual('a' + CharToText(9) + 'b' + CharToText(10) + 'c' + CharToText(13) + 'd&#x1;e&#x1F;', XmlUtilities.XmlEscape(InputText), 'Control characters must be replaced with character references.');
    end;

    [Test]
    procedure XmlEscapeEmptyText()
    begin
        Assert.AreEqual('', XmlUtilities.XmlEscape(''), 'Empty text must stay empty.');
    end;

    [Test]
    procedure XmlNameCharacterChecks()
    begin
        Assert.IsTrue(XmlUtilities.IsValidXmlNameStartCharacter('A'), 'A is a valid name start character.');
        Assert.IsTrue(XmlUtilities.IsValidXmlNameStartCharacter('_'), '_ is a valid name start character.');
        Assert.IsFalse(XmlUtilities.IsValidXmlNameStartCharacter('1'), '1 is not a valid name start character.');
        Assert.IsFalse(XmlUtilities.IsValidXmlNameStartCharacter('-'), '- is not a valid name start character.');
        Assert.IsTrue(XmlUtilities.IsValidXmlNameCharacter('1'), '1 is a valid name character.');
        Assert.IsTrue(XmlUtilities.IsValidXmlNameCharacter('-'), '- is a valid name character.');
        Assert.IsFalse(XmlUtilities.IsValidXmlNameCharacter(' '), 'Space is not a valid name character.');
        Assert.IsFalse(XmlUtilities.IsValidXmlNameCharacter('<'), '< is not a valid name character.');
        Assert.IsTrue(XmlUtilities.IsXmlRestrictedCharacter(ToChar(1)), 'Char 1 is restricted.');
        Assert.IsTrue(XmlUtilities.IsXmlRestrictedCharacter(ToChar(127)), 'Char 127 is restricted.');
        Assert.IsFalse(XmlUtilities.IsXmlRestrictedCharacter(ToChar(9)), 'Tab is not restricted.');
        Assert.IsFalse(XmlUtilities.IsXmlRestrictedCharacter('A'), 'A is not restricted.');
    end;

    [Test]
    procedure ReplaceXmlInvalidCharacters()
    begin
        Assert.AreEqual('ZZZZZ.ZZZ-ZZZZ:ZZZAZZBZZZZZ_ƒ0', XmlUtilities.ReplaceXmlInvalidCharacters(InvalidNameTok + 'ƒ0', 'Z'), 'Invalid characters must be replaced.');
        Assert.AreEqual('', XmlUtilities.ReplaceXmlInvalidCharacters('', 'Z'), 'Empty text must stay empty.');
        Assert.AreEqual('ValidName', XmlUtilities.ReplaceXmlInvalidCharacters('ValidName', 'Z'), 'A valid name must not change.');
    end;

    [Test]
    procedure GetUtf8BomSymbols()
    var
        Bom: Text;
        BomCode: Integer;
    begin
        Bom := XmlUtilities.GetUtf8BomSymbols();
        Assert.AreEqual(1, StrLen(Bom), 'The UTF-8 BOM must be one character.');
        BomCode := Bom[1];
        Assert.AreEqual(65279, BomCode, 'The UTF-8 BOM must be U+FEFF.');
    end;

    [Test]
    procedure ClearUtf8BomSymbols()
    var
        XmlText: Text;
    begin
        XmlText := XmlUtilities.GetUtf8BomSymbols() + '<root/>';
        XmlUtilities.ClearUtf8BomSymbols(XmlText);
        Assert.AreEqual('<root/>', XmlText, 'The BOM must be removed.');

        XmlUtilities.ClearUtf8BomSymbols(XmlText);
        Assert.AreEqual('<root/>', XmlText, 'Text without a BOM must not change.');

        XmlText := '<root>' + XmlUtilities.GetUtf8BomSymbols() + '</root>';
        XmlUtilities.ClearUtf8BomSymbols(XmlText);
        Assert.AreEqual('<root>' + XmlUtilities.GetUtf8BomSymbols() + '</root>', XmlText, 'Only a leading BOM must be removed.');
    end;

    [Test]
    procedure GetRelativePath()
    begin
        Assert.AreEqual('.', XmlUtilities.GetRelativePath('/gesmes:Envelope/Cube/Cube/Cube', '/gesmes:Envelope/Cube/Cube/Cube'), 'Same node.');
        Assert.AreEqual('.', XmlUtilities.GetRelativePath('/A/B', '/a/b'), 'The comparison must be case-insensitive.');
        Assert.AreEqual('../@time', XmlUtilities.GetRelativePath('/gesmes:Envelope/Cube/Cube/@time', '/gesmes:Envelope/Cube/Cube/Cube'), 'Node above base.');
        Assert.AreEqual('../../../rate/date/@time', XmlUtilities.GetRelativePath('/gesmes:Envelope/rate/date/@time', '/gesmes:Envelope/Cube/Cube/Cube'), 'Node three levels above base.');
        Assert.AreEqual('@currency', XmlUtilities.GetRelativePath('/gesmes:Envelope/Cube/Cube/Cube/@currency', '/gesmes:Envelope/Cube/Cube/Cube'), 'Node in base.');
        Assert.AreEqual('rate/@rate', XmlUtilities.GetRelativePath('/gesmes:Envelope/Cube/Cube/Cube/rate/@rate', '/gesmes:Envelope/Cube/Cube/Cube'), 'Node below base.');
        Assert.AreEqual('rate/rate/@rate', XmlUtilities.GetRelativePath('/gesmes:Envelope/Cube/Cube/Cube/rate/rate/@rate', '/gesmes:Envelope/Cube/Cube/Cube'), 'Node two levels below base.');
    end;

    [Test]
    procedure GetRelativePathEmptyNodePath()
    begin
        asserterror XmlUtilities.GetRelativePath('', '/gesmes:Envelope/Cube/Cube/Cube');
        Assert.ExpectedError(NodePathErr);
    end;

    [Test]
    procedure GetRelativePathEmptyBasePath()
    begin
        asserterror XmlUtilities.GetRelativePath('/gesmes:Envelope/Cube/Cube/@time', '');
        Assert.ExpectedError(BasePathErr);
    end;

    [Test]
    procedure TryGetXmlAsTextRemovesInsignificantWhitespace()
    var
        TempBlob: Codeunit "Temp Blob";
        Xml: Text;
    begin
        WriteText(TempBlob, '<?xml version="1.0" encoding="utf-8"?>' + CrLf() + '<root>' + CrLf() + '  <child attr="1">text</child>' + CrLf() + '  <empty />' + CrLf() + '</root>');
        Assert.IsTrue(XmlUtilities.TryGetXmlAsText(TempBlob.CreateInStream(), Xml), 'TryGetXmlAsText must succeed.');
        Assert.AreEqual('<?xml version="1.0" encoding="utf-8"?><root><child attr="1">text</child><empty /></root>', Xml, 'Unexpected XML text.');
    end;

    [Test]
    procedure TryGetXmlAsTextEmptyStream()
    var
        TempBlob: Codeunit "Temp Blob";
        Xml: Text;
    begin
        Assert.IsFalse(XmlUtilities.TryGetXmlAsText(TempBlob.CreateInStream(), Xml), 'TryGetXmlAsText must fail for an empty stream.');
        Assert.ExpectedError(EmptyStreamErr);
    end;

    [Test]
    procedure TryGetXmlAsTextInvalidXml()
    var
        TempBlob: Codeunit "Temp Blob";
        Xml: Text;
    begin
        WriteText(TempBlob, 'not xml');
        Assert.IsFalse(XmlUtilities.TryGetXmlAsText(TempBlob.CreateInStream(), Xml), 'TryGetXmlAsText must fail for invalid XML.');
    end;

    [Test]
    procedure TryTransformXmlToOutStream()
    var
        TempBlobXml: Codeunit "Temp Blob";
        TempBlobXsl: Codeunit "Temp Blob";
        TempBlobResult: Codeunit "Temp Blob";
        XmlInStream: InStream;
        XslInStream: InStream;
        ResultOutStream: OutStream;
        Xml: Text;
    begin
        WriteText(TempBlobXml, GetPersonsXml());
        WriteText(TempBlobXsl, GetPersonsXslt());
        XmlInStream := TempBlobXml.CreateInStream();
        XslInStream := TempBlobXsl.CreateInStream();
        ResultOutStream := TempBlobResult.CreateOutStream();

        Assert.IsTrue(XmlUtilities.TryTransformXmlToOutStream(XmlInStream, XslInStream, ResultOutStream), 'The transformation must succeed.');

        Assert.IsTrue(XmlUtilities.TryGetXmlAsText(TempBlobResult.CreateInStream(), Xml), 'The result must be valid XML.');
        Assert.AreEqual(GetTransformedPersonsXml(), Xml, 'Unexpected transformation result.');
    end;

    [Test]
    procedure TryTransformXmlToOutStreamInvalidXml()
    var
        TempBlobXml: Codeunit "Temp Blob";
        TempBlobXsl: Codeunit "Temp Blob";
        TempBlobResult: Codeunit "Temp Blob";
        XmlInStream: InStream;
        XslInStream: InStream;
        ResultOutStream: OutStream;
    begin
        WriteText(TempBlobXml, Format(CreateGuid()));
        WriteText(TempBlobXsl, GetPersonsXslt());
        XmlInStream := TempBlobXml.CreateInStream();
        XslInStream := TempBlobXsl.CreateInStream();
        ResultOutStream := TempBlobResult.CreateOutStream();

        Assert.IsFalse(XmlUtilities.TryTransformXmlToOutStream(XmlInStream, XslInStream, ResultOutStream), 'The transformation must fail for invalid XML.');
    end;

    [Test]
    procedure TryTransformXmlToOutStreamInvalidXslt()
    var
        TempBlobXml: Codeunit "Temp Blob";
        TempBlobXsl: Codeunit "Temp Blob";
        TempBlobResult: Codeunit "Temp Blob";
        XmlInStream: InStream;
        XslInStream: InStream;
        ResultOutStream: OutStream;
    begin
        WriteText(TempBlobXml, GetPersonsXml());
        WriteText(TempBlobXsl, Format(CreateGuid()));
        XmlInStream := TempBlobXml.CreateInStream();
        XslInStream := TempBlobXsl.CreateInStream();
        ResultOutStream := TempBlobResult.CreateOutStream();

        Assert.IsFalse(XmlUtilities.TryTransformXmlToOutStream(XmlInStream, XslInStream, ResultOutStream), 'The transformation must fail for an invalid stylesheet.');
    end;

    [Test]
    procedure TransformXmlText()
    begin
        Assert.AreEqual(GetTransformedPersonsXml(), XmlUtilities.TransformXmlText(GetPersonsXml(), GetPersonsXslt()), 'Unexpected transformation result.');
    end;

    [Test]
    procedure TransformXmlTextInvalidXml()
    begin
        asserterror XmlUtilities.TransformXmlText(Format(CreateGuid()), GetPersonsXslt());
        Assert.ExpectedError(XmlTransformErr);
    end;

    [Test]
    procedure TransformXmlTextInvalidXslt()
    begin
        asserterror XmlUtilities.TransformXmlText(GetPersonsXml(), Format(CreateGuid()));
        Assert.ExpectedError(XmlTransformErr);
    end;

    [Test]
    procedure TryFormatXml()
    var
        FormattedXml: Text;
    begin
        Assert.IsTrue(XmlUtilities.TryFormatXml(GetTransformedPersonsXml(), FormattedXml), 'Formatting must succeed.');
        Assert.AreEqual(
          '<?xml version="1.0" encoding="utf-8"?>' + CrLf() +
          '<transform>' + CrLf() +
          '  <record>' + CrLf() +
          '    <username>MP123456</username>' + CrLf() +
          '    <fullname>Ester Henderson</fullname>' + CrLf() +
          '  </record>' + CrLf() +
          '  <record>' + CrLf() +
          '    <username>PK123456</username>' + CrLf() +
          '    <fullname>Benjamin Chiu</fullname>' + CrLf() +
          '  </record>' + CrLf() +
          '</transform>', FormattedXml, 'Unexpected formatted XML.');
    end;

    [Test]
    procedure TryFormatXmlInvalidXml()
    var
        FormattedXml: Text;
    begin
        Assert.IsFalse(XmlUtilities.TryFormatXml(Format(CreateGuid()), FormattedXml), 'Formatting must fail for invalid XML.');
    end;

    [Test]
    procedure RemoveNamespaces()
    begin
        Assert.AreEqual(
          '<?xml version="1.0" encoding="utf-8"?><student><id>3235329</id><name>Jeff Smith</name><language>C#</language><rating>9.5</rating></student>',
          XmlUtilities.RemoveNamespaces(
            '<?xml version="1.0" encoding="utf-8"?>' +
            '<d:student xmlns:d="http://www.develop.com/student" xmlns:i="urn:schemas-develop-com:identifiers" xmlns:p="urn:schemas-develop-com:programming-languages">' +
            '<i:id>3235329</i:id><name>Jeff Smith</name><p:language>C#</p:language><d:rating>9.5</d:rating></d:student>'),
          'Namespaces must be removed.');
    end;

    [Test]
    procedure RemoveNamespacesInvalidXml()
    begin
        asserterror XmlUtilities.RemoveNamespaces(Format(CreateGuid()));
        Assert.ExpectedError(XmlTransformErr);
    end;

    [Test]
    procedure TryLoadXmlDocumentWithDtdExpandsInternalEntities()
    var
        TempBlob: Codeunit "Temp Blob";
        XmlDocument: XmlDocument;
        XmlDocumentType: XmlDocumentType;
        XmlNode: XmlNode;
        DocTypeName: Text;
    begin
        WriteText(TempBlob, '<?xml version="1.0"?><!DOCTYPE note [<!ELEMENT note (to)><!ELEMENT to (#PCDATA)><!ENTITY writer "Donald Duck">]><note><to>&writer;</to></note>');

        if not XmlUtilities.TryLoadXmlDocumentWithDtd(TempBlob.CreateInStream(), XmlDocument) then
            Assert.Fail('Loading a document with a DTD must succeed. Error: ' + GetLastErrorText());

        Assert.IsTrue(XmlDocument.SelectSingleNode('/note/to', XmlNode), 'The element must exist.');
        Assert.AreEqual('Donald Duck', XmlNode.AsXmlElement().InnerText(), 'The internal entity must be expanded.');
        Assert.IsTrue(XmlDocument.GetDocumentType(XmlDocumentType), 'The document type declaration must be kept.');
        XmlDocumentType.GetName(DocTypeName);
        Assert.AreEqual('note', DocTypeName, 'Unexpected document type name.');
    end;

    [Test]
    procedure TryLoadXmlDocumentWithDtdWithoutDocumentType()
    var
        TempBlob: Codeunit "Temp Blob";
        XmlDocument: XmlDocument;
        XmlDocumentType: XmlDocumentType;
        XmlNode: XmlNode;
    begin
        WriteText(TempBlob, '<?xml version="1.0"?><note><to>Daisy</to></note>');

        if not XmlUtilities.TryLoadXmlDocumentWithDtd(TempBlob.CreateInStream(), XmlDocument) then
            Assert.Fail('Loading a document without a DTD must succeed. Error: ' + GetLastErrorText());

        Assert.IsTrue(XmlDocument.SelectSingleNode('/note/to', XmlNode), 'The element must exist.');
        Assert.AreEqual('Daisy', XmlNode.AsXmlElement().InnerText(), 'Unexpected element text.');
        Assert.IsFalse(XmlDocument.GetDocumentType(XmlDocumentType), 'There must be no document type declaration.');
    end;

    [Test]
    procedure TryLoadXmlDocumentWithDtdDoesNotResolveExternalEntities()
    var
        TempBlob: Codeunit "Temp Blob";
        XmlDocument: XmlDocument;
        XmlNode: XmlNode;
    begin
        WriteText(TempBlob, '<?xml version="1.0"?><!DOCTYPE note [<!ENTITY ext SYSTEM "file:///c:/windows/win.ini">]><note>&ext;</note>');

        if not XmlUtilities.TryLoadXmlDocumentWithDtd(TempBlob.CreateInStream(), XmlDocument) then
            Assert.Fail('Loading a document with an external entity must succeed. Error: ' + GetLastErrorText());
        Assert.IsTrue(XmlDocument.SelectSingleNode('/note', XmlNode), 'The element must exist.');
        Assert.AreEqual('', XmlNode.AsXmlElement().InnerText(), 'External entities must not be resolved.');
    end;

    [Test]
    procedure TryLoadXmlDocumentWithDtdLimitsEntityExpansion()
    var
        TempBlob: Codeunit "Temp Blob";
        XmlDocument: XmlDocument;
    begin
        // An entity that expands to 100,000,000 characters exceeds the 10,000,000 character limit.
        WriteText(TempBlob,
          '<?xml version="1.0"?><!DOCTYPE lolz [<!ENTITY lol "lol">' +
          '<!ENTITY lol2 "&lol;&lol;&lol;&lol;&lol;&lol;&lol;&lol;&lol;&lol;">' +
          '<!ENTITY lol3 "&lol2;&lol2;&lol2;&lol2;&lol2;&lol2;&lol2;&lol2;&lol2;&lol2;">' +
          '<!ENTITY lol4 "&lol3;&lol3;&lol3;&lol3;&lol3;&lol3;&lol3;&lol3;&lol3;&lol3;">' +
          '<!ENTITY lol5 "&lol4;&lol4;&lol4;&lol4;&lol4;&lol4;&lol4;&lol4;&lol4;&lol4;">' +
          '<!ENTITY lol6 "&lol5;&lol5;&lol5;&lol5;&lol5;&lol5;&lol5;&lol5;&lol5;&lol5;">' +
          '<!ENTITY lol7 "&lol6;&lol6;&lol6;&lol6;&lol6;&lol6;&lol6;&lol6;&lol6;&lol6;">' +
          '<!ENTITY lol8 "&lol7;&lol7;&lol7;&lol7;&lol7;&lol7;&lol7;&lol7;&lol7;&lol7;">]><lolz>&lol8;</lolz>');

        Assert.IsFalse(XmlUtilities.TryLoadXmlDocumentWithDtd(TempBlob.CreateInStream(), XmlDocument), 'Loading a document whose entities expand beyond the limit must fail.');
    end;

    [Test]
    procedure TryLoadXmlDocumentWithDtdEmptyStream()
    var
        TempBlob: Codeunit "Temp Blob";
        XmlDocument: XmlDocument;
    begin
        Assert.IsFalse(XmlUtilities.TryLoadXmlDocumentWithDtd(TempBlob.CreateInStream(), XmlDocument), 'Loading an empty stream must fail.');
        Assert.ExpectedError(EmptyStreamErr);
    end;

    local procedure WriteText(var TempBlob: Codeunit "Temp Blob"; Content: Text)
    var
        OutStream: OutStream;
    begin
        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(Content);
    end;

    local procedure ToChar(CharCode: Integer) Result: Char
    begin
        Result := CharCode;
    end;

    local procedure CharToText(CharCode: Integer): Text
    begin
        exit(Format(ToChar(CharCode)));
    end;

    local procedure CrLf() NewLine: Text[2]
    begin
        NewLine[1] := 13;
        NewLine[2] := 10;
    end;

    local procedure GetPersonsXml(): Text
    begin
        exit(
          '<?xml version="1.0" encoding="UTF-8"?>' +
          '<persons>' +
          '<person username="MP123456"><name>Ester</name><surname>Henderson</surname></person>' +
          '<person username="PK123456"><name>Benjamin</name><surname>Chiu</surname></person>' +
          '</persons>');
    end;

    local procedure GetTransformedPersonsXml(): Text
    begin
        exit(
          '<?xml version="1.0" encoding="utf-8"?>' +
          '<transform>' +
          '<record><username>MP123456</username><fullname>Ester Henderson</fullname></record>' +
          '<record><username>PK123456</username><fullname>Benjamin Chiu</fullname></record>' +
          '</transform>');
    end;

    local procedure GetPersonsXslt(): Text
    begin
        exit(
          '<?xml version="1.0"?>' +
          '<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">' +
          '<xsl:output method="xml" indent="yes"/>' +
          '<xsl:template match="persons"><transform><xsl:apply-templates/></transform></xsl:template>' +
          '<xsl:template match="person"><record><xsl:apply-templates select="@*|*"/></record></xsl:template>' +
          '<xsl:template match="@username"><username><xsl:value-of select="."/></username></xsl:template>' +
          '<xsl:template match="name"><fullname><xsl:apply-templates/><xsl:apply-templates select="following-sibling::surname" mode="fullname"/></fullname></xsl:template>' +
          '<xsl:template match="surname"/>' +
          '<xsl:template match="surname" mode="fullname"><xsl:text> </xsl:text><xsl:apply-templates/></xsl:template>' +
          '</xsl:stylesheet>');
    end;
}
