// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

using System.Utilities;

codeunit 27001 "Export Accounts Xml Helper"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        XMLDoc: XmlDocument;
        CurrXMLElement: array[100] of XmlElement;
        Depth: Integer;
        NamespacePrefixGlobal: Text;
        NamespaceUriGlobal: Text;
        XPathParent: Text;
        XsiNamespaceUriTxt: label 'http://www.w3.org/2001/XMLSchema-instance', Locked = true;
        NotPossibleToInsertErr: label 'Not possible to insert element %1', Comment = '%1 - node text';

    procedure Initialize(RootNodeName: Text; NamespacePrefix: Text; NamespaceUri: Text; SchemaLocation: Text; XmlAttributes: Dictionary of [Text, Text]);
    begin
        Clear(XMLDoc);
        Clear(CurrXMLElement);
        Depth := 0;
        NamespacePrefixGlobal := NamespacePrefix;
        NamespaceUriGlobal := NamespaceUri;

        XMLDoc := XmlDocument.Create();
        XMLDoc.SetDeclaration(XmlDeclaration.Create('1.0', 'UTF-8', 'yes'));
        CreateRootWithNamespace(RootNodeName, SchemaLocation, XmlAttributes);
    end;

    local procedure CreateRootWithNamespace(RootNodeName: Text; SchemaLocation: Text; XmlAttributes: Dictionary of [Text, Text])
    var
        XmlAttributeName: Text;
        XmlAttributeValue: Text;
    begin
        Depth += 1;
        CurrXMLElement[Depth] := XmlElement.Create(RootNodeName, NamespaceUriGlobal);
        AddElementNameToXPath(RootNodeName);
        if NamespacePrefixGlobal <> '' then
            CurrXMLElement[Depth].Add(XmlAttribute.CreateNamespaceDeclaration(NamespacePrefixGlobal, NamespaceUriGlobal));
        foreach XmlAttributeName in XmlAttributes.Keys() do begin
            XmlAttributeValue := XmlAttributes.Get(XmlAttributeName);
            CurrXMLElement[Depth].Add(XmlAttribute.Create(XmlAttributeName, XmlAttributeValue));
        end;
        if SchemaLocation <> '' then begin
            CurrXMLElement[Depth].Add(XmlAttribute.CreateNamespaceDeclaration('xsi', XsiNamespaceUriTxt));
            CurrXMLElement[Depth].Add(XmlAttribute.Create('schemaLocation', XsiNamespaceUriTxt, SchemaLocation));
        end;
        XMLDoc.Add(CurrXMLElement[Depth]);
        XMLDoc.GetRoot(CurrXMLElement[Depth]);
    end;

    procedure AddNewNode(NodeName: Text)
    var
        NewXMLElement: XmlElement;
    begin
        AddXmlElement(NewXMLElement, NodeName, '');
        Depth += 1;
        CurrXMLElement[Depth] := NewXMLElement;
        AddElementNameToXPath(NodeName);
    end;

    procedure AddAttribute(AttributeName: Text; AttributeValue: Text)
    var
        NewXmlAttribute: XmlAttribute;
    begin
        NewXmlAttribute := XmlAttribute.Create(AttributeName, AttributeValue);
        if not CurrXMLElement[Depth].Add(NewXmlAttribute) then
            Error(NotPossibleToInsertErr, AttributeValue);
    end;

    local procedure AddXmlElement(var NewXMLElement: XmlElement; Name: Text; NodeText: Text)
    begin
        NewXMLElement := XmlElement.Create(Name, NamespaceUriGlobal, NodeText);
        if not CurrXMLElement[Depth].Add(NewXMLElement) then
            Error(NotPossibleToInsertErr, NodeText);
    end;

    procedure FinalizeNode()
    begin
        Depth -= 1;
        RemoveLastElementNameFromXPath();
        if Depth < 0 then
            Error('Incorrect XML structure');
    end;

    local procedure AddElementNameToXPath(ElementName: Text)
    begin
        XPathParent += ('/' + ElementName);
    end;

    local procedure RemoveLastElementNameFromXPath()
    begin
        XPathParent := XPathParent.Substring(1, XPathParent.LastIndexOf('/') - 1);
    end;

    procedure WriteXmlDocToTempBlob(var TempBlob: Codeunit "Temp Blob")
    var
        BlobOutStream: OutStream;
        XMLDocText: Text;
    begin
        TempBlob.CreateOutStream(BlobOutStream, TextEncoding::UTF8);
        XMLDoc.WriteTo(XMLDocText);
        BlobOutStream.WriteText(XMLDocText);
        Clear(XMLDoc);
    end;
}