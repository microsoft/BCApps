// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Interfactura.Tests;

using Microsoft.EServices.EDocument.Interfactura;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Sales.Customer;
using Microsoft.Sales.History;
using Microsoft.eServices.EDocument;
using System.Utilities;

codeunit 148756 "Carta Porte Fields Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;
    Permissions = tabledata "Sales Shipment Header" = rimd,
                  tabledata "Sales Shipment Line" = rimd,
                  tabledata "Company Information" = rm,
                  tabledata Customer = rimd,
                  tabledata Item = rimd,
                  tabledata Location = rimd,
                  tabledata "Unit of Measure" = rimd,
                  tabledata "SAT Address" = rimd,
                  tabledata "SAT Suburb" = rimd;

    var
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        CFDIXMLHelper: Codeunit "CFDI XML Helper MX";
        ExportInterfactura: Codeunit "Export Interfactura MX";
        CartaPorteNamespaceTxt: Label 'http://www.sat.gob.mx/CartaPorte31', Locked = true;

    [Test]
    procedure ISTMOAttributesExportedWhenISTMOEnabled()
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        CartaPorteElement: XmlElement;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] When SAT ISTMO is enabled on the shipment, the exporter writes RegistroISTMO, UbicacionPoloOrigen and UbicacionPoloDestino
        Initialize();

        // [GIVEN] A posted sales shipment with SAT ISTMO enabled and both poles set
        CreateSalesShipment(SalesShipmentHeader, false, '');
        SalesShipmentHeader."SAT ISTMO" := true;
        SalesShipmentHeader."SAT ISTMO Polo Origen" := '01';
        SalesShipmentHeader."SAT ISTMO Polo Destino" := '06';
        SalesShipmentHeader.Modify();

        // [WHEN] The shipment is exported as Carta Porte
        CartaPorteElement := ExportCartaPorte(SalesShipmentHeader);

        // [THEN] The ISTMO attributes are written with the shipment values
        Assert.AreEqual('Sí', GetXmlAttribute(CartaPorteElement, 'RegistroISTMO'), 'RegistroISTMO attribute value is incorrect.');
        Assert.AreEqual('01', GetXmlAttribute(CartaPorteElement, 'UbicacionPoloOrigen'), 'UbicacionPoloOrigen attribute value is incorrect.');
        Assert.AreEqual('06', GetXmlAttribute(CartaPorteElement, 'UbicacionPoloDestino'), 'UbicacionPoloDestino attribute value is incorrect.');
    end;

    [Test]
    procedure ISTMOAttributesNotExportedWhenISTMODisabled()
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        CartaPorteElement: XmlElement;
        Attribute: XmlAttribute;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] When SAT ISTMO is disabled on the shipment, the exporter does not write any ISTMO attribute
        Initialize();

        // [GIVEN] A posted sales shipment with SAT ISTMO disabled
        CreateSalesShipment(SalesShipmentHeader, false, '');

        // [WHEN] The shipment is exported as Carta Porte
        CartaPorteElement := ExportCartaPorte(SalesShipmentHeader);

        // [THEN] ISTMO attributes are absent
        Assert.IsFalse(CartaPorteElement.Attributes().Get('RegistroISTMO', Attribute), 'RegistroISTMO should not be present when ISTMO is disabled.');
        Assert.IsFalse(CartaPorteElement.Attributes().Get('UbicacionPoloOrigen', Attribute), 'UbicacionPoloOrigen should not be present when ISTMO is disabled.');
        Assert.IsFalse(CartaPorteElement.Attributes().Get('UbicacionPoloDestino', Attribute), 'UbicacionPoloDestino should not be present when ISTMO is disabled.');
    end;

    [Test]
    procedure ViaEntradaSalidaExportedWithConfiguredTransportType()
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        CartaPorteElement: XmlElement;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] For an international shipment, the exporter writes ViaEntradaSalida with the configured SAT Transport Type
        Initialize();

        // [GIVEN] A posted international sales shipment with SAT Transport Type 02 (Transporte Marítimo)
        CreateSalesShipment(SalesShipmentHeader, true, '02');

        // [WHEN] The shipment is exported as Carta Porte
        CartaPorteElement := ExportCartaPorte(SalesShipmentHeader);

        // [THEN] ViaEntradaSalida is the configured transport type
        Assert.AreEqual('02', GetXmlAttribute(CartaPorteElement, 'ViaEntradaSalida'), 'ViaEntradaSalida attribute value is incorrect.');
    end;

    [Test]
    procedure ViaEntradaSalidaDefaultsToAutotransporteWhenEmpty()
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        CartaPorteElement: XmlElement;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] For an international shipment with a blank SAT Transport Type, the exporter defaults ViaEntradaSalida to 01 (Autotransporte Federal)
        Initialize();

        // [GIVEN] A posted international sales shipment with a blank SAT Transport Type
        CreateSalesShipment(SalesShipmentHeader, true, '');

        // [WHEN] The shipment is exported as Carta Porte
        CartaPorteElement := ExportCartaPorte(SalesShipmentHeader);

        // [THEN] ViaEntradaSalida defaults to 01
        Assert.AreEqual('01', GetXmlAttribute(CartaPorteElement, 'ViaEntradaSalida'), 'ViaEntradaSalida must default to 01 when SAT Transport Type is blank.');
    end;

    [Test]
    procedure ISTMORegistroValuePreservesAccentedCharacter()
    var
        Document: XmlDocument;
        RootNode: XmlElement;
        RootXmlNode: XmlNode;
        CartaPorteXmlNode: XmlNode;
        XmlText: Text;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] The RegistroISTMO value 'Sí' (with accented í) is preserved correctly in the XML output
        Initialize();

        // [GIVEN] A CartaPorte XML node
        RootNode := XmlElement.Create('Complemento');
        Document.Add(RootNode.AsXmlNode());
        RootXmlNode := RootNode.AsXmlNode();
        CFDIXMLHelper.AddElementCartaPorte(RootXmlNode, 'CartaPorte', '', '', CartaPorteXmlNode);

        // [WHEN] RegistroISTMO is written with the accented value 'Sí'
        CFDIXMLHelper.AddAttributeSimple(CartaPorteXmlNode, 'RegistroISTMO', 'Sí');

        // [THEN] The XML text representation preserves the accented character
        Document.WriteTo(XmlText);
        Assert.IsTrue(XmlText.Contains('RegistroISTMO="S'), 'RegistroISTMO attribute is missing from XML output.');
        Assert.IsTrue(XmlText.Contains('í'), 'Accented character í in RegistroISTMO value was lost in XML output.');
    end;

    local procedure Initialize()
    var
        CompanyInformation: Record "Company Information";
    begin
        // Signing requires a SAT certificate with its private key; these tests validate XML content only
        if BindSubscription(this) then;
        CompanyInformation.Get();
        CompanyInformation."RFC Number" := 'MME910620Q85';
        CompanyInformation.Modify();
    end;

    local procedure CreateSalesShipment(var SalesShipmentHeader: Record "Sales Shipment Header"; ForeignTrade: Boolean; SATTransportType: Code[10])
    var
        SalesShipmentLine: Record "Sales Shipment Line";
        Customer: Record Customer;
        Item: Record Item;
        Location: Record Location;
        UnitOfMeasure: Record "Unit of Measure";
        SATAddressId: Integer;
    begin
        SATAddressId := CreateSATAddress();

        Location.Init();
        Location.Code := LibraryUtility.GenerateRandomCode(Location.FieldNo(Code), Database::Location);
        Location.Address := 'Avenida Reforma 100';
        Location."SAT Address ID" := SATAddressId;
        Location.Insert();

        Customer.Init();
        Customer."No." := LibraryUtility.GenerateRandomCode(Customer.FieldNo("No."), Database::Customer);
        Customer.Name := 'Carta Porte Customer';
        Customer."RFC No." := 'XAXX010101000';
        Customer."Country/Region Code" := 'MX';
        Customer.Insert();

        UnitOfMeasure.Init();
        UnitOfMeasure.Code := LibraryUtility.GenerateRandomCode(UnitOfMeasure.FieldNo(Code), Database::"Unit of Measure");
        UnitOfMeasure.Insert();

        Item.Init();
        Item."No." := LibraryUtility.GenerateRandomCode(Item.FieldNo("No."), Database::Item);
        Item.Description := 'Carta Porte Item';
        Item.Insert();

        SalesShipmentHeader.Init();
        SalesShipmentHeader."No." := LibraryUtility.GenerateRandomCode(SalesShipmentHeader.FieldNo("No."), Database::"Sales Shipment Header");
        SalesShipmentHeader."Sell-to Customer No." := Customer."No.";
        SalesShipmentHeader."Bill-to Customer No." := Customer."No.";
        SalesShipmentHeader."Location Code" := Location.Code;
        SalesShipmentHeader."Document Date" := WorkDate();
        SalesShipmentHeader."Posting Date" := WorkDate();
        SalesShipmentHeader."SAT Address ID" := SATAddressId;
        SalesShipmentHeader."Ship-to Address" := 'Calle Destino 200';
        SalesShipmentHeader."Transit-from Date/Time" := CreateDateTime(WorkDate(), 080000T);
        SalesShipmentHeader."Transit Hours" := 2;
        SalesShipmentHeader."Transit Distance" := 100;
        SalesShipmentHeader."Foreign Trade" := ForeignTrade;
        SalesShipmentHeader."SAT Transport Type" := SATTransportType;
        SalesShipmentHeader.Insert();

        SalesShipmentLine.Init();
        SalesShipmentLine."Document No." := SalesShipmentHeader."No.";
        SalesShipmentLine."Line No." := 10000;
        SalesShipmentLine.Type := SalesShipmentLine.Type::Item;
        SalesShipmentLine."No." := Item."No.";
        SalesShipmentLine.Description := Item.Description;
        SalesShipmentLine."Location Code" := Location.Code;
        SalesShipmentLine."Unit of Measure Code" := UnitOfMeasure.Code;
        SalesShipmentLine.Quantity := 1;
        SalesShipmentLine."Gross Weight" := 10;
        SalesShipmentLine.Insert();
    end;

    local procedure CreateSATAddress(): Integer
    var
        SATAddress: Record "SAT Address";
        SATSuburb: Record "SAT Suburb";
        SuburbId: Integer;
    begin
        if SATSuburb.FindLast() then
            SuburbId := SATSuburb.ID;
        SATSuburb.Init();
        SATSuburb.ID := SuburbId + 1;
        SATSuburb."Suburb Code" := '0001';
        SATSuburb."Postal Code" := '06600';
        SATSuburb.Insert();

        SATAddress.Init();
        SATAddress."Country/Region Code" := 'MX';
        SATAddress."SAT State Code" := 'CMX';
        SATAddress."SAT Suburb ID" := SATSuburb.ID;
        SATAddress.Insert();
        exit(SATAddress.Id);
    end;

    local procedure ExportCartaPorte(SalesShipmentHeader: Record "Sales Shipment Header"): XmlElement
    var
        SalesShipmentLine: Record "Sales Shipment Line";
        EDocument: Record "E-Document";
        TempBlob: Codeunit "Temp Blob";
        SourceHeader: RecordRef;
        SourceLines: RecordRef;
        Document: XmlDocument;
        NamespaceManager: XmlNamespaceManager;
        CartaPorteNode: XmlNode;
        InStream: InStream;
    begin
        SalesShipmentHeader.SetRecFilter();
        SourceHeader.GetTable(SalesShipmentHeader);
        SalesShipmentLine.SetRange("Document No.", SalesShipmentHeader."No.");
        SourceLines.GetTable(SalesShipmentLine);

        ExportInterfactura.Export(SourceHeader, SourceLines, EDocument, TempBlob, false);

        TempBlob.CreateInStream(InStream, TextEncoding::UTF8);
        XmlDocument.ReadFrom(InStream, Document);
        NamespaceManager.NameTable(Document.NameTable());
        NamespaceManager.AddNamespace('cartaporte31', CartaPorteNamespaceTxt);
        Assert.IsTrue(Document.SelectSingleNode('//cartaporte31:CartaPorte', NamespaceManager, CartaPorteNode), 'The CartaPorte node is missing from the exported XML.');
        exit(CartaPorteNode.AsXmlElement());
    end;

    local procedure GetXmlAttribute(Element: XmlElement; AttributeName: Text): Text
    var
        Attribute: XmlAttribute;
    begin
        if Element.Attributes().Get(AttributeName, Attribute) then
            exit(Attribute.Value());
        exit('');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Digital Sign MX", 'OnBeforeCreateDigitalSignature', '', false, false)]
    local procedure MockCreateDigitalSignature(OriginalString: Text; SetupId: Code[10]; var SignedString: Text; var IsHandled: Boolean)
    begin
        SignedString := 'TEST-SELLO';
        IsHandled := true;
    end;
}
