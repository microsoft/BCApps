// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Xml;

using System;
using System.Utilities;

codeunit 3017 "XML Utilities Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        SeparatorTxt: Label '/', Locked = true;
        DotDotTxt: Label '..', Locked = true;
        CharacterReferenceTxt: Label '&#x%1;', Locked = true;
        HexDigitsTxt: Label '0123456789ABCDEF', Locked = true;
        NodePathErr: Label 'Node path cannot be empty.';
        BasePathErr: Label 'Base path cannot be empty.';
        XmlTransformErr: Label 'The XML cannot be transformed.';
        XmlCannotBeLoadedErr: Label 'The XML cannot be loaded.';
        EmptyStreamErr: Label 'The stream is empty.';

    procedure XmlEscape(InputText: Text): Text
    var
        Result: TextBuilder;
        CurrentChar: Char;
        CharCode: Integer;
        Index: Integer;
    begin
        for Index := 1 to StrLen(InputText) do begin
            CurrentChar := InputText[Index];
            CharCode := CurrentChar;
            case CharCode of
                38:
                    Result.Append('&amp;');
                60:
                    Result.Append('&lt;');
                62:
                    Result.Append('&gt;');
                9, 10, 13:
                    Result.Append(Format(CurrentChar));
                0 .. 8, 11, 12, 14 .. 31, 65534, 65535:
                    Result.Append(StrSubstNo(CharacterReferenceTxt, ToHex(CharCode)));
                else
                    Result.Append(Format(CurrentChar));
            end;
        end;
        exit(Result.ToText());
    end;

    procedure IsValidXmlNameStartCharacter(InputChar: Char): Boolean
    var
        CharCode: Integer;
    begin
        if IsXmlRestrictedCharacter(InputChar) then
            exit(false);

        // NameStartChar ::= ":" | [A-Z] | "_" | [a-z] | [#xC0-#xD6] | [#xD8-#xF6] | [#xF8-#x2FF] | [#x370-#x37D] | [#x37F-#x1FFF] | [#x200C-#x200D] | [#x2070-#x218F] | [#x2C00-#x2FEF] | [#x3001-#xD7FF] | [#xF900-#xFDCF] | [#xFDF0-#xFFFD] | [#x10000-#xEFFF
        if InputChar in [':', '_', 'A' .. 'Z', 'a' .. 'z', 'Ç' .. 'ƒ', 'á' .. '´'] then
            exit(true);

        CharCode := InputChar;
        exit(CharCode in [192 .. 214, 216 .. 246, 248 .. 767, 880 .. 893, 895 .. 8191, 8204 .. 8205,
                          8304 .. 8591, 11264 .. 12271, 12289 .. 55259, 63744 .. 64975, 65008 .. 65533, 65536 .. 983039]);
    end;

    procedure IsValidXmlNameCharacter(InputChar: Char): Boolean
    var
        CharCode: Integer;
    begin
        // NameChar ::= NameStartChar | "-" | "." | [0-9] | #xB7 | [#x0300-#x036F] | [#x203F-#x2040]
        if IsValidXmlNameStartCharacter(InputChar) then
            exit(true);

        if InputChar in ['-', '.', '0' .. '9'] then
            exit(true);

        CharCode := InputChar;
        exit(CharCode in [183, 768 .. 879, 8255 .. 8256]);
    end;

    procedure IsXmlRestrictedCharacter(InputChar: Char): Boolean
    var
        CharCode: Integer;
    begin
        // RestrictedChar ::= [#x1-#x8] | [#xB-#xC] | [#xE-#x1F] | [#x7F-#x84] | [#x86-#x9F]
        CharCode := InputChar;
        exit(CharCode in [1 .. 8, 11 .. 12, 14 .. 31, 127 .. 132, 134 .. 159]);
    end;

    procedure ReplaceXmlInvalidCharacters(InputText: Text; ReplaceChar: Char): Text
    var
        Result: Text;
        Index: Integer;
    begin
        if InputText = '' then
            exit('');

        Result := InputText;

        if not IsValidXmlNameStartCharacter(InputText[1]) then
            Result[1] := ReplaceChar;
        for Index := 2 to StrLen(InputText) do
            if not IsValidXmlNameCharacter(InputText[Index]) then
                Result[Index] := ReplaceChar;

        exit(Result);
    end;

    procedure GetUtf8BomSymbols() ByteOrderMarkUtf8: Text
    var
        ByteOrderMarkChar: Char;
    begin
        ByteOrderMarkChar := 65279;
        ByteOrderMarkUtf8 := Format(ByteOrderMarkChar);
    end;

    procedure ClearUtf8BomSymbols(var XmlText: Text)
    var
        ByteOrderMarkUtf8: Text;
    begin
        ByteOrderMarkUtf8 := GetUtf8BomSymbols();
        if StrPos(XmlText, ByteOrderMarkUtf8) = 1 then
            XmlText := DelStr(XmlText, 1, StrLen(ByteOrderMarkUtf8));
    end;

    procedure GetRelativePath(NodePath: Text; BasePath: Text) Result: Text
    var
        BaseParts: List of [Text];
        NodeParts: List of [Text];
        CommonCount: Integer;
        Part: Integer;
        Done: Boolean;
    begin
        if NodePath = '' then
            Error(NodePathErr);

        if BasePath = '' then
            Error(BasePathErr);

        if LowerCase(NodePath) = LowerCase(BasePath) then
            exit('.');

        NodeParts := NodePath.Split(SeparatorTxt);
        BaseParts := BasePath.Split(SeparatorTxt);

        // Cut off the common path parts
        CommonCount := 0;
        while (CommonCount < NodeParts.Count()) and (CommonCount < BaseParts.Count()) and not Done do begin
            Done := LowerCase(NodeParts.Get(CommonCount + 1)) <> LowerCase(BaseParts.Get(CommonCount + 1));
            if not Done then
                CommonCount += 1;
        end;

        // Add .. for the way up from Base
        for Part := CommonCount + 1 to BaseParts.Count() do
            Result += SeparatorTxt + DotDotTxt;

        // Append the remaining part of the path
        for Part := CommonCount + 1 to NodeParts.Count() do
            Result += SeparatorTxt + NodeParts.Get(Part);

        // Cut off leading separator
        Result := CopyStr(Result, 2);
    end;

    procedure GetXmlAsText(InStream: InStream; var Xml: Text)
    var
        DotNetXmlDocument: DotNet XmlDocument;
    begin
        if InStream.EOS then
            Error(EmptyStreamErr);
        DotNetXmlDocument := DotNetXmlDocument.XmlDocument();
        DotNetXmlDocument.PreserveWhitespace(false);
        DotNetXmlDocument.Load(InStream);
        Xml := DotNetXmlDocument.OuterXml();
    end;

    procedure FormatXml(XmlText: Text; var FormattedXmlText: Text)
    var
        XDocument: DotNet XDocument;
        NewLine: Text[2];
    begin
        NewLine[1] := 13;
        NewLine[2] := 10;
        XDocument := XDocument.Parse(XmlText);
        FormattedXmlText := XDocument.Declaration.ToString() + NewLine + XDocument.ToString();
    end;

    procedure TransformXmlToOutStream(var XmlInStream: InStream; var XslInStream: InStream; var XmlOutStream: OutStream)
    var
        XslCompiledTransform: DotNet XslCompiledTransform;
        XslReader: DotNet XmlReader;
        XmlReader: DotNet XmlReader;
        XmlWriter: DotNet XmlWriter;
        DotNetXmlDocument: DotNet XmlDocument;
        XmlTextReader: DotNet XmlTextReader;
        StringReader: DotNet StringReader;
    begin
        DotNetXmlDocument := DotNetXmlDocument.XmlDocument();
        DotNetXmlDocument.PreserveWhitespace(false);

        CreateXmlReaderIgnoringDtd(XmlInStream, XmlReader);
        DotNetXmlDocument.Load(XmlReader);

        CreateXmlReaderIgnoringDtd(XslInStream, XslReader);
        XslCompiledTransform := XslCompiledTransform.XslCompiledTransform();
        XslCompiledTransform.Load(XslReader);

        XmlWriter := XmlWriter.Create(XmlOutStream);
        XmlTextReader := XmlTextReader.XmlTextReader(StringReader.StringReader(DotNetXmlDocument.DocumentElement.OuterXml));
        XslCompiledTransform.Transform(XmlTextReader, XmlWriter);
        XmlWriter.Flush();

        XmlReader.Close();
        XslReader.Close();
        XmlWriter.Close();
    end;

    procedure TransformXmlText(XmlInText: Text; XslInText: Text): Text
    var
        TempBlobXmlIn: Codeunit "Temp Blob";
        TempBlobXsl: Codeunit "Temp Blob";
        TempBlobXmlOut: Codeunit "Temp Blob";
        XmlInStream: InStream;
        XslInStream: InStream;
        XmlOutStream: OutStream;
        XslOutStream: OutStream;
        XmlText: Text;
    begin
        TempBlobXmlIn.CreateOutStream(XmlOutStream, TextEncoding::UTF8);
        XmlOutStream.WriteText(XmlInText);

        TempBlobXsl.CreateOutStream(XslOutStream, TextEncoding::UTF8);
        XslOutStream.WriteText(XslInText);

        TempBlobXmlIn.CreateInStream(XmlInStream);
        TempBlobXsl.CreateInStream(XslInStream);
        TempBlobXmlOut.CreateOutStream(XmlOutStream);
        if not TryTransformXmlToOutStream(XmlInStream, XslInStream, XmlOutStream) then
            Error(XmlTransformErr);

        TempBlobXmlOut.CreateInStream(XmlInStream);
        if not TryGetXmlAsText(XmlInStream, XmlText) then
            Error(XmlCannotBeLoadedErr);
        exit(XmlText);
    end;

    [TryFunction]
    local procedure TryTransformXmlToOutStream(var XmlInStream: InStream; var XslInStream: InStream; var XmlOutStream: OutStream)
    begin
        TransformXmlToOutStream(XmlInStream, XslInStream, XmlOutStream);
    end;

    [TryFunction]
    local procedure TryGetXmlAsText(InStream: InStream; var Xml: Text)
    begin
        GetXmlAsText(InStream, Xml);
    end;

    procedure RemoveNamespaces(XmlText: Text): Text
    begin
        exit(TransformXmlText(XmlText, GetRemoveNamespacesXsltText()));
    end;

    procedure LoadXmlDocumentWithDtd(InStream: InStream; var XmlDoc: XmlDocument)
    var
        DotNetXmlDocument: DotNet XmlDocument;
        DotNetXmlDocumentType: DotNet XmlDocumentType;
        XmlReaderSettings: DotNet XmlReaderSettings;
        DotNetXmlReader: DotNet XmlReader;
        XmlReadOptions: XmlReadOptions;
        DocTypeName: Text;
        DocTypePublicId: Text;
        DocTypeSystemId: Text;
        DocTypeInternalSubset: Text;
        HasDocumentType: Boolean;
    begin
        if InStream.EOS then
            Error(EmptyStreamErr);

        XmlReaderSettings := XmlReaderSettings.XmlReaderSettings();
        XmlReaderSettings.DtdProcessing := 2; // DtdProcessing.Parse, assigned as an integer because DtdProcessing.Parse conflicts with the Enum.Parse method.
        // The default XmlReaderSettings never resolve external DTDs or entities and limit entity expansion to 10,000,000 characters,
        // which protects against XXE and entity expansion attacks. Do not set an XmlResolver.

        DotNetXmlReader := DotNetXmlReader.Create(InStream, XmlReaderSettings);
        DotNetXmlDocument := DotNetXmlDocument.XmlDocument();
        DotNetXmlDocument.Load(DotNetXmlReader);
        DotNetXmlReader.Close();

        // The native XmlDocument does not accept DTDs, so the document type declaration is removed before conversion and added back afterwards.
        DotNetXmlDocumentType := DotNetXmlDocument.DocumentType;
        HasDocumentType := not IsNull(DotNetXmlDocumentType);
        if HasDocumentType then begin
            DocTypeName := DotNetXmlDocumentType.Name;
            DocTypePublicId := DotNetXmlDocumentType.PublicId;
            DocTypeSystemId := DotNetXmlDocumentType.SystemId;
            DocTypeInternalSubset := DotNetXmlDocumentType.InternalSubset;
            DotNetXmlDocument.RemoveChild(DotNetXmlDocumentType);
        end;

        XmlReadOptions.PreserveWhitespace := true;
        if not XmlDocument.ReadFrom(DotNetXmlDocument.OuterXml, XmlReadOptions, XmlDoc) then
            Error(XmlCannotBeLoadedErr);

        if HasDocumentType then
            XmlDoc.AddFirst(XmlDocumentType.Create(DocTypeName, DocTypePublicId, DocTypeSystemId, DocTypeInternalSubset));
    end;

    local procedure CreateXmlReaderIgnoringDtd(var XmlInStream: InStream; var XmlReader: DotNet XmlReader)
    var
        XmlReaderSettings: DotNet XmlReaderSettings;
        DtdProcessing: DotNet DtdProcessing;
    begin
        XmlReaderSettings := XmlReaderSettings.XmlReaderSettings();
        XmlReaderSettings.DtdProcessing := DtdProcessing.Ignore;
        XmlReader := XmlReader.Create(XmlInStream, XmlReaderSettings);
    end;

    local procedure GetRemoveNamespacesXsltText(): Text
    begin
        exit(
          '<?xml version="1.0" encoding="UTF-8"?>' +
          '<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">' +
          '<xsl:output method="xml" encoding="UTF-8" />' +
          '<xsl:template match="/">' +
          '<xsl:copy>' +
          '<xsl:apply-templates />' +
          '</xsl:copy>' +
          '</xsl:template>' +
          '<xsl:template match="*">' +
          '<xsl:element name="{local-name()}">' +
          '<xsl:apply-templates select="@* | node()" />' +
          '</xsl:element>' +
          '</xsl:template>' +
          '<xsl:template match="@*">' +
          '<xsl:attribute name="{local-name()}"><xsl:value-of select="."/></xsl:attribute>' +
          '</xsl:template>' +
          '<xsl:template match="text() | processing-instruction() | comment()">' +
          '<xsl:copy />' +
          '</xsl:template>' +
          '</xsl:stylesheet>');
    end;

    local procedure ToHex(Value: Integer) Result: Text
    begin
        if Value = 0 then
            exit('0');
        while Value > 0 do begin
            Result := CopyStr(HexDigitsTxt, (Value mod 16) + 1, 1) + Result;
            Value := Value div 16;
        end;
    end;
}
