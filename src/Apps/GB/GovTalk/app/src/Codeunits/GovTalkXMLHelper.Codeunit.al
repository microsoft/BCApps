// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.GovTalk;

using System.Utilities;

codeunit 10562 "GovTalk XML Helper"
{
    Access = Internal;

    procedure CreateDocumentWithRootElement(NodeName: Text; NameSpace: Text; var RootXmlElement: XmlElement)
    var
        GovTalkXmlDocument: XmlDocument;
    begin
        GovTalkXmlDocument := XmlDocument.Create();
        RootXmlElement := XmlElement.Create(NodeName, NameSpace);
        GovTalkXmlDocument.Add(RootXmlElement);
    end;

    [NonDebuggable]
    procedure AddElement(var ParentXmlElement: XmlElement; NodeName: Text; NodeText: Text; NameSpace: Text; var CreatedXmlElement: XmlElement)
    begin
        // An empty text node would be serialized as <Name></Name> instead of <Name />.
        if NodeText <> '' then
            CreatedXmlElement := XmlElement.Create(NodeName, NameSpace, NodeText)
        else
            CreatedXmlElement := XmlElement.Create(NodeName, NameSpace);
        ParentXmlElement.Add(CreatedXmlElement);
    end;

    procedure AddNamespaceDeclaration(var ParentXmlElement: XmlElement; Prefix: Text; NameSpace: Text)
    begin
        ParentXmlElement.Add(XmlAttribute.CreateNamespaceDeclaration(Prefix, NameSpace));
    end;

    /// <summary>
    /// Replaces the content of the element with a single text node, like setting InnerText on a DotNet XmlElement.
    /// </summary>
    [NonDebuggable]
    procedure SetInnerText(var TargetXmlElement: XmlElement; NewText: Text)
    begin
        TargetXmlElement.RemoveNodes();
        TargetXmlElement.Add(XmlText.Create(NewText));
    end;

    procedure FindNode(RootXmlElement: XmlElement; XPath: Text; Prefix: Text; NameSpace: Text; var FoundXmlNode: XmlNode): Boolean
    var
        XmlNamespaceManager: XmlNamespaceManager;
    begin
        CreateNamespaceManager(RootXmlElement, Prefix, NameSpace, XmlNamespaceManager);
        exit(RootXmlElement.SelectSingleNode(XPath, XmlNamespaceManager, FoundXmlNode));
    end;

    procedure FindElement(RootXmlElement: XmlElement; XPath: Text; Prefix: Text; NameSpace: Text; var FoundXmlElement: XmlElement): Boolean
    var
        FoundXmlNode: XmlNode;
    begin
        if not FindNode(RootXmlElement, XPath, Prefix, NameSpace, FoundXmlNode) then
            exit(false);
        if not FoundXmlNode.IsXmlElement() then
            exit(false);
        FoundXmlElement := FoundXmlNode.AsXmlElement();
        exit(true);
    end;

    procedure FindNodes(RootXmlElement: XmlElement; XPath: Text; Prefix: Text; NameSpace: Text; var FoundXmlNodeList: XmlNodeList): Boolean
    var
        XmlNamespaceManager: XmlNamespaceManager;
    begin
        CreateNamespaceManager(RootXmlElement, Prefix, NameSpace, XmlNamespaceManager);
        exit(RootXmlElement.SelectNodes(XPath, XmlNamespaceManager, FoundXmlNodeList));
    end;

    procedure FindNodeText(RootXmlElement: XmlElement; XPath: Text; Prefix: Text; NameSpace: Text): Text
    var
        FoundXmlElement: XmlElement;
    begin
        if not FindElement(RootXmlElement, XPath, Prefix, NameSpace, FoundXmlElement) then
            exit('');
        exit(FoundXmlElement.InnerText());
    end;

    procedure FindNodeText(RootXmlNode: XmlNode; XPath: Text; Prefix: Text; NameSpace: Text): Text
    begin
        if not RootXmlNode.IsXmlElement() then
            exit('');
        exit(FindNodeText(RootXmlNode.AsXmlElement(), XPath, Prefix, NameSpace));
    end;

    local procedure CreateNamespaceManager(RootXmlElement: XmlElement; Prefix: Text; NameSpace: Text; var XmlNamespaceManager: XmlNamespaceManager)
    var
        RootXmlDocument: XmlDocument;
    begin
        if RootXmlElement.GetDocument(RootXmlDocument) then
            XmlNamespaceManager.NameTable(RootXmlDocument.NameTable());
        XmlNamespaceManager.AddNamespace(Prefix, NameSpace);
    end;

    procedure LoadXmlFromInStream(XmlInStream: InStream; var RootXmlElement: XmlElement): Boolean
    var
        LoadedXmlDocument: XmlDocument;
    begin
        if not XmlDocument.ReadFrom(XmlInStream, LoadedXmlDocument) then
            exit(false);
        RemoveWhitespaceNodes(LoadedXmlDocument.AsXmlNode());
        exit(LoadedXmlDocument.GetRoot(RootXmlElement));
    end;

    procedure LoadXmlFromText(XmlText: Text; var RootXmlElement: XmlElement): Boolean
    var
        LoadedXmlDocument: XmlDocument;
    begin
        if not XmlDocument.ReadFrom(XmlText, LoadedXmlDocument) then
            exit(false);
        RemoveWhitespaceNodes(LoadedXmlDocument.AsXmlNode());
        exit(LoadedXmlDocument.GetRoot(RootXmlElement));
    end;

    // Native ReadFrom keeps whitespace-only text nodes, whereas the previously used DotNet XmlDocument dropped them on load.
    local procedure RemoveWhitespaceNodes(ParentXmlNode: XmlNode)
    var
        ChildXmlNodes: XmlNodeList;
        ChildXmlNode: XmlNode;
        Index: Integer;
    begin
        if not GetChildNodes(ParentXmlNode, ChildXmlNodes) then
            exit;

        Index := 1;
        while Index <= ChildXmlNodes.Count() do begin
            ChildXmlNodes.Get(Index, ChildXmlNode);
            if IsWhitespaceNode(ChildXmlNode) then begin
                ChildXmlNode.Remove();
                GetChildNodes(ParentXmlNode, ChildXmlNodes);
            end else begin
                RemoveWhitespaceNodes(ChildXmlNode);
                Index += 1;
            end;
        end;
    end;

    local procedure GetChildNodes(ParentXmlNode: XmlNode; var ChildXmlNodes: XmlNodeList): Boolean
    begin
        if ParentXmlNode.IsXmlDocument() then begin
            ChildXmlNodes := ParentXmlNode.AsXmlDocument().GetChildNodes();
            exit(true);
        end;
        if ParentXmlNode.IsXmlElement() then begin
            ChildXmlNodes := ParentXmlNode.AsXmlElement().GetChildNodes();
            exit(true);
        end;
        exit(false);
    end;

    local procedure IsWhitespaceNode(XmlNode: XmlNode): Boolean
    begin
        if not XmlNode.IsXmlText() then
            exit(false);
        exit(DelChr(XmlNode.AsXmlText().Value(), '=', GetWhitespaceCharacters()) = '');
    end;

    local procedure GetWhitespaceCharacters(): Text
    var
        Tab: Char;
        LineFeed: Char;
        CarriageReturn: Char;
    begin
        Tab := 9;
        LineFeed := 10;
        CarriageReturn := 13;
        exit(' ' + Format(Tab) + Format(LineFeed) + Format(CarriageReturn));
    end;

    /// <summary>
    /// Writes the document that owns the element the same way the previously used DotNet XmlDocument.Save did:
    /// indented unless whitespace is preserved, and with an XML declaration only when the document has one.
    /// </summary>
    procedure WriteXmlToOutStream(RootXmlElement: XmlElement; PreserveWhitespace: Boolean; var XmlOutStream: OutStream)
    var
        OwnerXmlDocument: XmlDocument;
        XmlDeclaration: XmlDeclaration;
        XmlWriteOptions: XmlWriteOptions;
        XmlText: Text;
    begin
        if not PreserveWhitespace then begin
            WriteIndentedXmlToOutStream(RootXmlElement, XmlOutStream);
            exit;
        end;

        XmlWriteOptions.PreserveWhitespace(true);
        if RootXmlElement.GetDocument(OwnerXmlDocument) then
            if OwnerXmlDocument.GetDeclaration(XmlDeclaration) then begin
                OwnerXmlDocument.WriteTo(XmlWriteOptions, XmlOutStream);
                exit;
            end;
        RootXmlElement.WriteTo(XmlWriteOptions, XmlText);
        XmlOutStream.WriteText(XmlText);
    end;

    local procedure WriteIndentedXmlToOutStream(RootXmlElement: XmlElement; var XmlOutStream: OutStream)
    var
        OwnerXmlDocument: XmlDocument;
        CopyXmlDocument: XmlDocument;
        CopyRootXmlElement: XmlElement;
        XmlDeclaration: XmlDeclaration;
        XmlText: Text;
    begin
        // Work on a copy so that the padding added below does not change the inner text of the original elements.
        XmlDocument.ReadFrom(GetXmlAsText(RootXmlElement), CopyXmlDocument);
        CopyXmlDocument.GetRoot(CopyRootXmlElement);
        PadEmptyElements(CopyRootXmlElement, 0);
        if RootXmlElement.GetDocument(OwnerXmlDocument) then
            if OwnerXmlDocument.GetDeclaration(XmlDeclaration) then begin
                CopyXmlDocument.SetDeclaration(XmlDeclaration);
                CopyXmlDocument.WriteTo(XmlOutStream);
                exit;
            end;
        CopyRootXmlElement.WriteTo(XmlText);
        XmlOutStream.WriteText(XmlText);
    end;

    // DotNet writes an element read as <Name></Name> as a start tag and an end tag on separate, indented lines.
    local procedure PadEmptyElements(ParentXmlElement: XmlElement; Depth: Integer)
    var
        ChildXmlNode: XmlNode;
        CarriageReturn: Char;
        LineFeed: Char;
    begin
        if ParentXmlElement.GetChildNodes().Count() = 0 then begin
            if not ParentXmlElement.IsEmpty() then begin
                CarriageReturn := 13;
                LineFeed := 10;
                ParentXmlElement.Add(XmlText.Create(Format(CarriageReturn) + Format(LineFeed) + PadStr('', 2 * Depth)));
            end;
            exit;
        end;
        foreach ChildXmlNode in ParentXmlElement.GetChildNodes() do
            if ChildXmlNode.IsXmlElement() then
                PadEmptyElements(ChildXmlNode.AsXmlElement(), Depth + 1);
    end;

    procedure WriteXmlToTempBlob(RootXmlElement: XmlElement; PreserveWhitespace: Boolean; var TempBlob: Codeunit "Temp Blob")
    var
        XmlOutStream: OutStream;
    begin
        TempBlob.CreateOutStream(XmlOutStream, TextEncoding::UTF8);
        WriteXmlToOutStream(RootXmlElement, PreserveWhitespace, XmlOutStream);
    end;

    procedure CopyXmlToOutStream(RootXmlElement: XmlElement; PreserveWhitespace: Boolean; var TargetOutStream: OutStream)
    var
        TempBlob: Codeunit "Temp Blob";
        XmlInStream: InStream;
    begin
        WriteXmlToTempBlob(RootXmlElement, PreserveWhitespace, TempBlob);
        TempBlob.CreateInStream(XmlInStream);
        CopyStream(TargetOutStream, XmlInStream);
    end;

    /// <summary>
    /// Returns the element as unindented XML text without an XML declaration, like DotNet XmlNode.OuterXml.
    /// </summary>
    procedure GetXmlAsText(RootXmlElement: XmlElement): Text
    var
        XmlWriteOptions: XmlWriteOptions;
        XmlText: Text;
    begin
        XmlWriteOptions.PreserveWhitespace(true);
        RootXmlElement.WriteTo(XmlWriteOptions, XmlText);
        exit(XmlText);
    end;
}
