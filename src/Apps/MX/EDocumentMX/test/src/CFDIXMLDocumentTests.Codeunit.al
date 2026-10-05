// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Interfactura.Tests;

using Microsoft.EServices.EDocument.Interfactura;

codeunit 148750 "CFDI XML Document Tests"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        CFDIXMLHelper: Codeunit "CFDI XML Helper MX";

    [Test]
    procedure FormatAmountUsesTwoDecimalsForCurrencyAmounts()
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] Currency amounts are formatted with two decimals
        Initialize();

        // [WHEN] An amount with currency precision is formatted
        // [THEN] The formatted value contains two decimals
        Assert.AreEqual('123.45', CFDIXMLHelper.FormatAmount(123.45), 'The currency amount was formatted incorrectly.');
    end;

    [Test]
    procedure FormatAmountUsesSixDecimalsForHighPrecisionAmounts()
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] High precision amounts retain six decimals
        Initialize();

        // [WHEN] A high precision amount is formatted
        // [THEN] The formatted value contains six decimals
        Assert.AreEqual('123.456789', CFDIXMLHelper.FormatAmount(123.456789), 'The high precision amount was formatted incorrectly.');
    end;

    [Test]
    procedure AddElementCFDICreatesCFDINode()
    var
        Document: XmlDocument;
        RootNode: XmlElement;
        CreatedNode: XmlNode;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] A CFDI element is created with the CFDI namespace
        Initialize();

        // [GIVEN] An XML root node
        RootNode := XmlElement.Create('Comprobante');
        Document.Add(RootNode.AsXmlNode());

        // [WHEN] A CFDI child element is added
        Assert.IsTrue(AddCFDINode(RootNode, CreatedNode), 'The CFDI node was not created.');

        // [THEN] The node has the expected name and value
        Assert.AreEqual('cfdi:Emisor', CreatedNode.AsXmlElement().Name, 'The CFDI node name is incorrect.');
        Assert.AreEqual('RFC123', CreatedNode.AsXmlElement().InnerText, 'The CFDI node value is incorrect.');
    end;

    [Test]
    procedure AddAttributeRemovesInvalidPipeCharacters()
    var
        Node: XmlElement;
        Attribute: XmlAttribute;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] XML attributes do not contain pipe characters
        Initialize();

        // [GIVEN] An XML node
        Node := XmlElement.Create('Comprobante');

        // [WHEN] An attribute containing a pipe is added
        CFDIXMLHelper.AddAttribute(Node.AsXmlNode(), 'Descripcion', 'Valor | normal');

        // [THEN] The invalid character is removed
        Node.Attributes().Get('Descripcion', Attribute);
        Assert.AreEqual('Valor normal', Attribute.Value(), 'The invalid pipe character was not removed.');
    end;

    [Test]
    procedure InitXMLNamespacesRegistersCFDIAndCartaPorteNamespaces()
    var
        NamespaceManager: XmlNamespaceManager;
        NamespaceUri: Text;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] CFDI XML namespace aliases are registered
        Initialize();

        // [WHEN] The namespace manager is initialized
        CFDIXMLHelper.InitXMLNamespaces(NamespaceManager);

        // [THEN] The CFDI and Carta Porte namespaces can be resolved
        NamespaceManager.LookupNamespace('cfdi', NamespaceUri);
        Assert.AreEqual('http://www.sat.gob.mx/cfd/4', NamespaceUri, 'The CFDI namespace is incorrect.');
        NamespaceManager.LookupNamespace('cartaporte31', NamespaceUri);
        Assert.AreEqual('http://www.sat.gob.mx/CartaPorte31', NamespaceUri, 'The Carta Porte namespace is incorrect.');
    end;

    [Test]
    procedure FormatDateTimeUsesSATDateTimeFormat()
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] A document date is formatted using the SAT date-time format
        Initialize();

        // [WHEN] A date-time is formatted
        // [THEN] The result uses an ISO-like SAT representation
        Assert.AreEqual('2026-01-02T13:14:15', CFDIXMLHelper.FormatDateTime(CreateDateTime(20260102D, 131415T)), 'The date-time was formatted incorrectly.');
    end;

    local procedure Initialize()
    begin
    end;

    local procedure AddCFDINode(var RootNode: XmlElement; var CreatedNode: XmlNode): Boolean
    var
        RootXmlNode: XmlNode;
    begin
        RootXmlNode := RootNode.AsXmlNode();
        exit(CFDIXMLHelper.AddElementCFDI(RootXmlNode, 'Emisor', 'RFC123', CreatedNode));
    end;

}
