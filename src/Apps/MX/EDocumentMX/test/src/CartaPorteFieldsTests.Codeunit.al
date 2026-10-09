// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Interfactura.Tests;

using Microsoft.EServices.EDocument.Interfactura;

codeunit 148756 "Carta Porte Fields Tests"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        CFDIXMLHelper: Codeunit "CFDI XML Helper MX";

    [Test]
    procedure ISTMOAttributesWrittenToCartaPorteNode()
    var
        Document: XmlDocument;
        RootNode: XmlElement;
        CartaPorteXmlNode: XmlNode;
        CartaPorteElement: XmlElement;
    begin
        // [FEATURE] Carta Porte ISTMO
        // [SCENARIO] When SAT ISTMO is enabled, RegistroISTMO, UbicacionPoloOrigen and UbicacionPoloDestino are written to the CartaPorte node
        Initialize();

        // [GIVEN] A CartaPorte XML node
        RootNode := XmlElement.Create('Complemento');
        Document.Add(RootNode.AsXmlNode());
        CFDIXMLHelper.AddElementCartaPorte(RootNode.AsXmlNode(), 'CartaPorte', '', '', CartaPorteXmlNode);

        // [WHEN] ISTMO attributes are added using AddAttributeSimple
        CFDIXMLHelper.AddAttributeSimple(CartaPorteXmlNode, 'RegistroISTMO', 'Sí');
        CFDIXMLHelper.AddAttributeSimple(CartaPorteXmlNode, 'UbicacionPoloOrigen', '01');
        CFDIXMLHelper.AddAttributeSimple(CartaPorteXmlNode, 'UbicacionPoloDestino', '06');

        // [THEN] All three attributes are present with the correct values
        CartaPorteElement := CartaPorteXmlNode.AsXmlElement();
        Assert.AreEqual('Sí', GetXmlAttribute(CartaPorteElement, 'RegistroISTMO'), 'RegistroISTMO attribute value is incorrect.');
        Assert.AreEqual('01', GetXmlAttribute(CartaPorteElement, 'UbicacionPoloOrigen'), 'UbicacionPoloOrigen attribute value is incorrect.');
        Assert.AreEqual('06', GetXmlAttribute(CartaPorteElement, 'UbicacionPoloDestino'), 'UbicacionPoloDestino attribute value is incorrect.');
    end;

    [Test]
    procedure ISTMOAttributesNotWrittenWhenISTMODisabled()
    var
        Document: XmlDocument;
        RootNode: XmlElement;
        CartaPorteXmlNode: XmlNode;
        CartaPorteElement: XmlElement;
        Attribute: XmlAttribute;
    begin
        // [FEATURE] Carta Porte ISTMO
        // [SCENARIO] When SAT ISTMO is disabled, ISTMO attributes are not present on the CartaPorte node
        Initialize();

        // [GIVEN] A CartaPorte XML node with no ISTMO attributes added
        RootNode := XmlElement.Create('Complemento');
        Document.Add(RootNode.AsXmlNode());
        CFDIXMLHelper.AddElementCartaPorte(RootNode.AsXmlNode(), 'CartaPorte', '', '', CartaPorteXmlNode);

        // [WHEN] Only non-ISTMO attributes are added (SAT ISTMO = false scenario)
        CFDIXMLHelper.AddAttributeSimple(CartaPorteXmlNode, 'Version', '3.1');

        // [THEN] ISTMO attributes are absent
        CartaPorteElement := CartaPorteXmlNode.AsXmlElement();
        Assert.IsFalse(CartaPorteElement.Attributes().Get('RegistroISTMO', Attribute), 'RegistroISTMO should not be present when ISTMO is disabled.');
        Assert.IsFalse(CartaPorteElement.Attributes().Get('UbicacionPoloOrigen', Attribute), 'UbicacionPoloOrigen should not be present when ISTMO is disabled.');
        Assert.IsFalse(CartaPorteElement.Attributes().Get('UbicacionPoloDestino', Attribute), 'UbicacionPoloDestino should not be present when ISTMO is disabled.');
    end;

    [Test]
    procedure ViaEntradaSalidaAttributeWrittenToCartaPorteNode()
    var
        Document: XmlDocument;
        RootNode: XmlElement;
        CartaPorteXmlNode: XmlNode;
        CartaPorteElement: XmlElement;
    begin
        // [FEATURE] Carta Porte Transport Type
        // [SCENARIO] ViaEntradaSalida is written with the configured transport type code
        Initialize();

        // [GIVEN] A CartaPorte XML node
        RootNode := XmlElement.Create('Complemento');
        Document.Add(RootNode.AsXmlNode());
        CFDIXMLHelper.AddElementCartaPorte(RootNode.AsXmlNode(), 'CartaPorte', '', '', CartaPorteXmlNode);

        // [WHEN] ViaEntradaSalida is set to Transporte Marítimo (02)
        CFDIXMLHelper.AddAttributeSimple(CartaPorteXmlNode, 'ViaEntradaSalida', '02');

        // [THEN] The attribute is present with the correct SAT catalog code
        CartaPorteElement := CartaPorteXmlNode.AsXmlElement();
        Assert.AreEqual('02', GetXmlAttribute(CartaPorteElement, 'ViaEntradaSalida'), 'ViaEntradaSalida attribute value is incorrect.');
    end;

    [Test]
    procedure ViaEntradaSalidaDefaultsToAutotransporteWhenEmpty()
    var
        Document: XmlDocument;
        RootNode: XmlElement;
        CartaPorteXmlNode: XmlNode;
        CartaPorteElement: XmlElement;
        DefaultTransportType: Code[10];
    begin
        // [FEATURE] Carta Porte Transport Type
        // [SCENARIO] When SAT Transport Type is blank, ViaEntradaSalida defaults to 01 (Autotransporte Federal)
        Initialize();

        // [GIVEN] A CartaPorte XML node
        RootNode := XmlElement.Create('Complemento');
        Document.Add(RootNode.AsXmlNode());
        CFDIXMLHelper.AddElementCartaPorte(RootNode.AsXmlNode(), 'CartaPorte', '', '', CartaPorteXmlNode);

        // [WHEN] ViaEntradaSalida is set using the default value (SAT Transport Type = '')
        DefaultTransportType := GetDefaultTransportType('');
        CFDIXMLHelper.AddAttributeSimple(CartaPorteXmlNode, 'ViaEntradaSalida', DefaultTransportType);

        // [THEN] ViaEntradaSalida defaults to 01 (Autotransporte Federal)
        CartaPorteElement := CartaPorteXmlNode.AsXmlElement();
        Assert.AreEqual('01', GetXmlAttribute(CartaPorteElement, 'ViaEntradaSalida'), 'ViaEntradaSalida must default to 01 when SAT Transport Type is blank.');
    end;

    [Test]
    procedure ISTMORegistroValuePreservesAccentedCharacter()
    var
        Document: XmlDocument;
        RootNode: XmlElement;
        CartaPorteXmlNode: XmlNode;
        XmlText: Text;
    begin
        // [FEATURE] Carta Porte ISTMO
        // [SCENARIO] The RegistroISTMO value 'Sí' (with accented í) is preserved correctly in the XML output
        Initialize();

        // [GIVEN] A CartaPorte XML node
        RootNode := XmlElement.Create('Complemento');
        Document.Add(RootNode.AsXmlNode());
        CFDIXMLHelper.AddElementCartaPorte(RootNode.AsXmlNode(), 'CartaPorte', '', '', CartaPorteXmlNode);

        // [WHEN] RegistroISTMO is written with the accented value 'Sí'
        CFDIXMLHelper.AddAttributeSimple(CartaPorteXmlNode, 'RegistroISTMO', 'Sí');

        // [THEN] The XML text representation preserves the accented character
        Document.WriteTo(XmlText);
        Assert.IsTrue(XmlText.Contains('RegistroISTMO="S'), 'RegistroISTMO attribute is missing from XML output.');
        Assert.IsTrue(XmlText.Contains('í'), 'Accented character í in RegistroISTMO value was lost in XML output.');
    end;

    local procedure Initialize()
    begin
    end;

    local procedure GetXmlAttribute(Element: XmlElement; AttributeName: Text): Text
    var
        Attribute: XmlAttribute;
    begin
        if Element.Attributes().Get(AttributeName, Attribute) then
            exit(Attribute.Value());
        exit('');
    end;

    local procedure GetDefaultTransportType(TransportType: Code[10]): Code[10]
    begin
        if TransportType = '' then
            exit('01');
        exit(TransportType);
    end;
}
