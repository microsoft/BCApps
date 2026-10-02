// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Interfactura.Tests;

using Microsoft.EServices.EDocument.Interfactura;

codeunit 2168 "Carta Porte XML Document Tests"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        CFDIXMLHelper: Codeunit "CFDI XML Helper MX";

    [Test]
    procedure AddElementCartaPorteCreatesCartaPorteNode()
    var
        Document: XmlDocument;
        RootNode: XmlElement;
        CreatedNode: XmlNode;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] A Carta Porte complement node is created with its namespace
        Initialize();

        // [GIVEN] A CFDI root node
        RootNode := XmlElement.Create('Complemento');
        Document.Add(RootNode.AsXmlNode());

        // [WHEN] A Carta Porte node is added
        Assert.IsTrue(AddCartaPorteNode(RootNode, CreatedNode), 'The Carta Porte node was not created.');

        // [THEN] The node uses the Carta Porte namespace
        Assert.AreEqual('CartaPorte', CreatedNode.AsXmlElement().LocalName, 'The Carta Porte node name is incorrect.');
        Assert.AreEqual('http://www.sat.gob.mx/CartaPorte31', CreatedNode.AsXmlElement().NamespaceUri, 'The Carta Porte namespace is incorrect.');
    end;

    [Test]
    procedure AddElementCCEWithNamespaceCreatesComercioExteriorNode()
    var
        Document: XmlDocument;
        RootNode: XmlElement;
        CreatedNode: XmlNode;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] A Comercio Exterior node is created with its namespace
        Initialize();

        // [GIVEN] A CFDI root node
        RootNode := XmlElement.Create('Complemento');
        Document.Add(RootNode.AsXmlNode());

        // [WHEN] A Comercio Exterior node is added
        Assert.IsTrue(AddComercioExteriorNode(RootNode, CreatedNode), 'The Comercio Exterior node was not created.');

        // [THEN] The node is created successfully
        Assert.AreEqual('cce20:ComercioExterior', CreatedNode.AsXmlElement().Name, 'The Comercio Exterior node name is incorrect.');
        Assert.AreEqual('http://www.sat.gob.mx/ComercioExterior20', CreatedNode.AsXmlElement().NamespaceUri, 'The Comercio Exterior namespace is incorrect.');
    end;

    [Test]
    procedure AddElementCartaPorteRejectsNonElementParent()
    var
        TextNode: XmlNode;
        CreatedNode: XmlNode;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] A Carta Porte node cannot be added under a text node
        Initialize();

        // [GIVEN] A non-element XML node
        TextNode := XmlText.Create('text').AsXmlNode();

        // [WHEN] A Carta Porte node is added
        // [THEN] The operation returns false
        Assert.IsFalse(CFDIXMLHelper.AddElementCartaPorte(TextNode, 'CartaPorte', '', '', CreatedNode), 'A node was added to a non-element parent.');
    end;

    local procedure Initialize()
    begin
    end;

    local procedure AddCartaPorteNode(var RootNode: XmlElement; var CreatedNode: XmlNode): Boolean
    var
        RootXmlNode: XmlNode;
    begin
        RootXmlNode := RootNode.AsXmlNode();
        exit(CFDIXMLHelper.AddElementCartaPorte(RootXmlNode, 'CartaPorte', '', '', CreatedNode));
    end;

    local procedure AddComercioExteriorNode(var RootNode: XmlElement; var CreatedNode: XmlNode): Boolean
    var
        RootXmlNode: XmlNode;
    begin
        RootXmlNode := RootNode.AsXmlNode();
        exit(CFDIXMLHelper.AddElementCCE(RootXmlNode, 'ComercioExterior', '', 'http://www.sat.gob.mx/ComercioExterior20', CreatedNode));
    end;
}
