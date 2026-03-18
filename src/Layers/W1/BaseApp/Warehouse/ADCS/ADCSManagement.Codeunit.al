// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.ADCS;

using System;
using System.Xml;

codeunit 7700 "ADCS Management"
{
    SingleInstance = true;

    trigger OnRun()
    begin
    end;

    var
        InboundDocument: DotNet XmlDocument;
        OutboundDocument: DotNet XmlDocument;

    [Scope('OnPrem')]
    procedure SendXMLReply(xmlout: DotNet XmlDocument)
    begin
        OutboundDocument := xmlout;
    end;

    [Scope('OnPrem')]
    procedure SendError(ErrorString: Text[250])
    var
        XMLDOMMgt: Codeunit "XML DOM Management";
        RootNode: DotNet XmlNode;
        Child: DotNet XmlNode;
        ReturnedNode: DotNet XmlNode;
    begin
        OutboundDocument := InboundDocument;

        // Error text
        Clear(XMLDOMMgt);
        RootNode := OutboundDocument.DocumentElement;

        if XMLDOMMgt.FindNode(RootNode, 'Header', ReturnedNode) then begin
            if XMLDOMMgt.FindNode(RootNode, 'Header/Input', Child) then
                ReturnedNode.RemoveChild(Child);
            if XMLDOMMgt.FindNode(RootNode, 'Header/Comment', Child) then
                ReturnedNode.RemoveChild(Child);
            XMLDOMMgt.AddElement(ReturnedNode, 'Comment', ErrorString, '', ReturnedNode);
        end;

        Clear(RootNode);
        Clear(Child);
    end;

    [Scope('OnPrem')]
    procedure ProcessDocument(Document: DotNet XmlDocument)
    var
        MiniformMgt: Codeunit "Miniform Management";
    begin
        InboundDocument := Document;
        MiniformMgt.ReceiveXML(InboundDocument);
    end;

    [Scope('OnPrem')]
    procedure GetOutboundDocument(var Document: DotNet XmlDocument)
    begin
        Document := OutboundDocument;
    end;
}

