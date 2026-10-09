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
        XmlContent: Text;
    begin
        Clear(Document);
        if not OutboundDocument.GetRoot(RootElement) then
            exit;
        OutboundDocument.WriteTo(XmlContent);
        Document := Document.XmlDocument();
        Document.LoadXml(XmlContent);
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
