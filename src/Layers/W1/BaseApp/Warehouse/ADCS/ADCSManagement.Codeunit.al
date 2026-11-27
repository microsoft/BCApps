// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.ADCS;

#if not CLEAN30
using System;
#endif

codeunit 7700 "ADCS Management"
{
    SingleInstance = true;

    trigger OnRun()
    begin
    end;

    var
        InboundDocument: XmlDocument;
        OutboundDocument: XmlDocument;

    [Scope('OnPrem')]
    procedure SendXMLReply(xmlout: XmlDocument)
    begin
        OutboundDocument := xmlout;
    end;

    [Scope('OnPrem')]
    procedure SendError(ErrorString: Text[250])
    var
        RootElement: XmlElement;
        Child: XmlNode;
        ReturnedNode: XmlNode;
        CommentElement: XmlElement;
    begin
        OutboundDocument := InboundDocument;

        // Error text
        if not OutboundDocument.GetRoot(RootElement) then
            exit;

        if RootElement.SelectSingleNode('Header', ReturnedNode) then begin
            if RootElement.SelectSingleNode('Header/Input', Child) then
                Child.Remove();
            if RootElement.SelectSingleNode('Header/Comment', Child) then
                Child.Remove();
            CommentElement := XmlElement.Create('Comment');
            if ErrorString <> '' then
                CommentElement.Add(XmlText.Create(ErrorString));
            ReturnedNode.AsXmlElement().Add(CommentElement);
        end;
    end;

    [Scope('OnPrem')]
    procedure ProcessDocument(Document: XmlDocument)
    var
        MiniformMgt: Codeunit "Miniform Management";
    begin
        InboundDocument := Document;
        MiniformMgt.ReceiveXML(InboundDocument);
    end;

    [Scope('OnPrem')]
    procedure GetOutboundDocument(var Document: XmlDocument)
    begin
        Document := OutboundDocument;
    end;

    /// <summary>
    /// Serializes the document the same way as the former DotNet XmlDocument.OuterXml: no indentation, and an XML declaration only when the document has one.
    /// </summary>
    internal procedure WriteDocumentToText(XmlDoc: XmlDocument) Result: Text
    var
        XmlDecl: XmlDeclaration;
        RootElement: XmlElement;
        XmlWriteOptions: XmlWriteOptions;
        RootText: Text;
        DeclarationEncoding: Text;
        DeclarationStandalone: Text;
    begin
        if not XmlDoc.GetRoot(RootElement) then
            exit('');

        XmlWriteOptions.PreserveWhitespace(true);
        RootElement.WriteTo(XmlWriteOptions, RootText);

        if XmlDoc.GetDeclaration(XmlDecl) then begin
            DeclarationEncoding := XmlDecl.Encoding();
            DeclarationStandalone := XmlDecl.Standalone();
            Result := '<?xml version="' + XmlDecl.Version() + '"';
            if StrLen(DeclarationEncoding) > 0 then
                Result += ' encoding="' + DeclarationEncoding + '"';
            if StrLen(DeclarationStandalone) > 0 then
                Result += ' standalone="' + DeclarationStandalone + '"';
            Result += '?>';
        end;
        Result += RootText;
    end;

#if not CLEAN30
    [Scope('OnPrem')]
    [Obsolete('Replaced by SendXMLReply with a parameter of the native XmlDocument type.', '30.0')]
    procedure SendXMLReply(xmlout: DotNet XmlDocument)
    begin
        ConvertToXmlDocument(xmlout, OutboundDocument);
    end;

    [Scope('OnPrem')]
    [Obsolete('Replaced by ProcessDocument with a parameter of the native XmlDocument type.', '30.0')]
    procedure ProcessDocument(Document: DotNet XmlDocument)
    var
        NativeXmlDocument: XmlDocument;
    begin
        ConvertToXmlDocument(Document, NativeXmlDocument);
        ProcessDocument(NativeXmlDocument);
    end;

    [Scope('OnPrem')]
    [Obsolete('Replaced by GetOutboundDocument with a parameter of the native XmlDocument type.', '30.0')]
    procedure GetOutboundDocument(var Document: DotNet XmlDocument)
    var
        RootElement: XmlElement;
    begin
        Clear(Document);
        if not OutboundDocument.GetRoot(RootElement) then
            exit;
        Document := Document.XmlDocument();
        Document.LoadXml(WriteDocumentToText(OutboundDocument));
    end;

    local procedure ConvertToXmlDocument(DotNetXmlDocument: DotNet XmlDocument; var NativeXmlDocument: XmlDocument)
    begin
        Clear(NativeXmlDocument);
        if IsNull(DotNetXmlDocument) then
            exit;
        if IsNull(DotNetXmlDocument.DocumentElement) then
            exit;
        XmlDocument.ReadFrom(DotNetXmlDocument.OuterXml(), NativeXmlDocument);
    end;
#endif
}
