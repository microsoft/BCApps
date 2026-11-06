// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Interfactura.Tests;

using Microsoft.EServices.EDocument.Interfactura;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.Reporting;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.eServices.EDocument;
using System.Utilities;

codeunit 148756 "Carta Porte Fields Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;
    Permissions = tabledata "Sales Header" = rimd,
                  tabledata "Sales Line" = rimd,
                  tabledata "Sales Shipment Header" = rimd,
                  tabledata "Sales Shipment Line" = rimd,
                  tabledata "E-Document" = rimd,
                  tabledata "E-Document Service" = rimd,
                  tabledata "Document Sending Profile" = rimd,
                  tabledata "Company Information" = rm,
                  tabledata Customer = rimd,
                  tabledata "Country/Region" = rimd,
                  tabledata Item = rimd,
                  tabledata Location = rimd,
                  tabledata "Unit of Measure" = rimd,
                  tabledata "SAT Address" = rimd,
                  tabledata "SAT Suburb" = rimd;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryUtility: Codeunit "Library - Utility";
        CFDIXMLHelper: Codeunit "CFDI XML Helper MX";
        ExportInterfactura: Codeunit "Export Interfactura MX";
        CFDIServiceCodeTok: Label 'MX-CFDI', Locked = true;
        CartaPorteNamespaceTxt: Label 'http://www.sat.gob.mx/CartaPorte31', Locked = true;
        ComercioExteriorNamespaceTxt: Label 'http://www.sat.gob.mx/ComercioExterior20', Locked = true;
        ForeignRFCTxt: Label 'XEXX010101000', Locked = true;
        ForeignVATRegNoTxt: Label '123456789', Locked = true;
        ForeignSATCountryCodeTxt: Label 'USA', Locked = true;
        CustomsRegimeTxt: Label 'EXD', Locked = true;
        TransferReasonTxt: Label '02', Locked = true;
        IncotermTxt: Label 'FOB', Locked = true;
        TariffNoTxt: Label '84713001', Locked = true;
        CustomsUnitTxt: Label '06', Locked = true;
        NodeMissingErr: Label 'The node %1 is missing from the exported XML.', Comment = '%1 = XPath of the node', Locked = true;

    [Test]
    procedure ISTMOAttributesExportedWhenISTMOEnabled()
    var
        SalesShipmentHeader: Record "Sales Header";
        CartaPorteElement: XmlElement;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] When SAT ISTMO is enabled on the sales order, the exporter writes RegistroISTMO, UbicacionPoloOrigen and UbicacionPoloDestino
        Initialize();

        // [GIVEN] A sales order with SAT ISTMO enabled and both poles set
        CreateSalesShipment(SalesShipmentHeader, false, '');
        SalesShipmentHeader."SAT ISTMO" := true;
        SalesShipmentHeader."SAT ISTMO Polo Origen" := '01';
        SalesShipmentHeader."SAT ISTMO Polo Destino" := '06';
        SalesShipmentHeader.Modify();

        // [WHEN] The order is exported as Carta Porte
        CartaPorteElement := ExportCartaPorte(SalesShipmentHeader);

        // [THEN] The ISTMO attributes are written with the order values
        Assert.AreEqual('Sí', GetXmlAttribute(CartaPorteElement, 'RegistroISTMO'), 'RegistroISTMO attribute value is incorrect.');
        Assert.AreEqual('01', GetXmlAttribute(CartaPorteElement, 'UbicacionPoloOrigen'), 'UbicacionPoloOrigen attribute value is incorrect.');
        Assert.AreEqual('06', GetXmlAttribute(CartaPorteElement, 'UbicacionPoloDestino'), 'UbicacionPoloDestino attribute value is incorrect.');
    end;

    [Test]
    procedure ISTMOAttributesNotExportedWhenISTMODisabled()
    var
        SalesShipmentHeader: Record "Sales Header";
        CartaPorteElement: XmlElement;
        Attribute: XmlAttribute;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] When SAT ISTMO is disabled on the sales order, the exporter does not write any ISTMO attribute
        Initialize();

        // [GIVEN] A sales order with SAT ISTMO disabled
        CreateSalesShipment(SalesShipmentHeader, false, '');

        // [WHEN] The order is exported as Carta Porte
        CartaPorteElement := ExportCartaPorte(SalesShipmentHeader);

        // [THEN] ISTMO attributes are absent
        Assert.IsFalse(CartaPorteElement.Attributes().Get('RegistroISTMO', Attribute), 'RegistroISTMO should not be present when ISTMO is disabled.');
        Assert.IsFalse(CartaPorteElement.Attributes().Get('UbicacionPoloOrigen', Attribute), 'UbicacionPoloOrigen should not be present when ISTMO is disabled.');
        Assert.IsFalse(CartaPorteElement.Attributes().Get('UbicacionPoloDestino', Attribute), 'UbicacionPoloDestino should not be present when ISTMO is disabled.');
    end;

    [Test]
    procedure ViaEntradaSalidaExportedWithConfiguredTransportType()
    var
        SalesShipmentHeader: Record "Sales Header";
        CartaPorteElement: XmlElement;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] For an international sales order, the exporter writes ViaEntradaSalida with the configured SAT Transport Type
        Initialize();

        // [GIVEN] A sales order with SAT Transport Type 02 (Transporte Marítimo)
        CreateSalesShipment(SalesShipmentHeader, true, '02');

        // [WHEN] The order is exported as Carta Porte
        CartaPorteElement := ExportCartaPorte(SalesShipmentHeader);

        // [THEN] ViaEntradaSalida is the configured transport type
        Assert.AreEqual('02', GetXmlAttribute(CartaPorteElement, 'ViaEntradaSalida'), 'ViaEntradaSalida attribute value is incorrect.');
    end;

    [Test]
    procedure ViaEntradaSalidaDefaultsToAutotransporteWhenEmpty()
    var
        SalesShipmentHeader: Record "Sales Header";
        CartaPorteElement: XmlElement;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] For an international sales order with a blank SAT Transport Type, the exporter defaults ViaEntradaSalida to 01 (Autotransporte Federal)
        Initialize();

        // [GIVEN] A sales order with a blank SAT Transport Type
        CreateSalesShipment(SalesShipmentHeader, true, '');

        // [WHEN] The order is exported as Carta Porte
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

    [Test]
    procedure DomesticShipmentIsNotExportedAsInternationalTransport()
    var
        SalesShipmentHeader: Record "Sales Header";
        Document: XmlDocument;
        CartaPorteElement: XmlElement;
        DestinationElement: XmlElement;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] A sales order without foreign trade is exported as domestic transport without customs data
        Initialize();

        // [GIVEN] A sales order without foreign trade
        CreateSalesShipment(SalesShipmentHeader, false, '');

        // [WHEN] The order is exported as Carta Porte
        Document := ExportCartaPorteDocument(SalesShipmentHeader);

        // [THEN] TranspInternac is No and no international attributes are written
        CartaPorteElement := SelectElement(Document, '//cartaporte31:CartaPorte');
        Assert.AreEqual('No', GetXmlAttribute(CartaPorteElement, 'TranspInternac'), 'TranspInternac must be No for a domestic shipment.');
        Assert.AreEqual('', GetXmlAttribute(CartaPorteElement, 'EntradaSalidaMerc'), 'EntradaSalidaMerc must not be exported for a domestic shipment.');
        Assert.AreEqual('', GetXmlAttribute(CartaPorteElement, 'PaisOrigenDestino'), 'PaisOrigenDestino must not be exported for a domestic shipment.');
        Assert.IsFalse(NodeExists(Document, '//cartaporte31:RegimenesAduaneros'), 'RegimenesAduaneros must not be exported for a domestic shipment.');

        // [THEN] The foreign trade complement is not exported and the destination has no foreign tax data
        Assert.IsFalse(NodeExists(Document, '//cce20:ComercioExterior'), 'ComercioExterior must not be exported for a domestic shipment.');
        DestinationElement := SelectElement(Document, '//cartaporte31:Ubicacion[@TipoUbicacion="Destino"]');
        Assert.AreEqual('', GetXmlAttribute(DestinationElement, 'NumRegIdTrib'), 'NumRegIdTrib must not be exported for a domestic destination.');
        Assert.AreEqual('', GetXmlAttribute(DestinationElement, 'ResidenciaFiscal'), 'ResidenciaFiscal must not be exported for a domestic destination.');
    end;

    [Test]
    procedure InternationalShipmentExportsCustomsAndForeignReceiverData()
    var
        SalesShipmentHeader: Record "Sales Header";
        Document: XmlDocument;
        CartaPorteElement: XmlElement;
        MercanciaElement: XmlElement;
        DestinationElement: XmlElement;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] An international sales order exports the customs regime, tariff data and the foreign receiver tax data
        Initialize();

        // [GIVEN] A sales order with foreign trade to a foreign customer
        CreateSalesShipment(SalesShipmentHeader, true, '01');
        SetInternationalShipmentData(SalesShipmentHeader);

        // [WHEN] The order is exported as Carta Porte
        Document := ExportCartaPorteDocument(SalesShipmentHeader);

        // [THEN] The CartaPorte node is marked as international transport leaving Mexico
        CartaPorteElement := SelectElement(Document, '//cartaporte31:CartaPorte');
        Assert.AreEqual('Sí', GetXmlAttribute(CartaPorteElement, 'TranspInternac'), 'TranspInternac must be Sí for an international shipment.');
        Assert.AreEqual('Salida', GetXmlAttribute(CartaPorteElement, 'EntradaSalidaMerc'), 'EntradaSalidaMerc is incorrect.');
        Assert.AreEqual(ForeignSATCountryCodeTxt, GetXmlAttribute(CartaPorteElement, 'PaisOrigenDestino'), 'PaisOrigenDestino must be the SAT code of the ship-to country.');

        // [THEN] The customs regime is exported
        Assert.AreEqual(CustomsRegimeTxt, GetXmlAttribute(SelectElement(Document, '//cartaporte31:RegimenAduaneroCCP'), 'RegimenAduanero'), 'RegimenAduanero is incorrect.');

        // [THEN] The goods carry the tariff number and the foreign trade UUID placeholder
        MercanciaElement := SelectElement(Document, '//cartaporte31:Mercancia');
        Assert.AreEqual(TariffNoTxt, GetXmlAttribute(MercanciaElement, 'FraccionArancelaria'), 'FraccionArancelaria is incorrect.');
        Assert.AreEqual('00000000-0000-0000-0000-000000000000', GetXmlAttribute(MercanciaElement, 'UUIDComercioExt'), 'UUIDComercioExt is incorrect.');

        // [THEN] The destination carries the foreign tax registration and the fiscal residence
        DestinationElement := SelectElement(Document, '//cartaporte31:Ubicacion[@TipoUbicacion="Destino"]');
        Assert.AreEqual(ForeignVATRegNoTxt, GetXmlAttribute(DestinationElement, 'NumRegIdTrib'), 'NumRegIdTrib is incorrect.');
        Assert.AreEqual(ForeignSATCountryCodeTxt, GetXmlAttribute(DestinationElement, 'ResidenciaFiscal'), 'ResidenciaFiscal is incorrect.');
    end;

    [Test]
    procedure InternationalShipmentExportsComercioExteriorInUSD()
    var
        SalesShipmentHeader: Record "Sales Header";
        Document: XmlDocument;
        ComercioExteriorElement: XmlElement;
        MercanciaElement: XmlElement;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] An international sales order exports the foreign trade complement with values converted to USD
        Initialize();

        // [GIVEN] A sales order with 2 units at 100 MXN and a USD exchange rate of 20
        CreateSalesShipment(SalesShipmentHeader, true, '01');
        SetInternationalShipmentData(SalesShipmentHeader);

        // [WHEN] The order is exported as Carta Porte
        Document := ExportCartaPorteDocument(SalesShipmentHeader);

        // [THEN] The complement header carries the transfer reason, Incoterm, exchange rate and USD total
        ComercioExteriorElement := SelectElement(Document, '//cce20:ComercioExterior');
        Assert.AreEqual(TransferReasonTxt, GetXmlAttribute(ComercioExteriorElement, 'MotivoTraslado'), 'MotivoTraslado is incorrect.');
        Assert.AreEqual(IncotermTxt, GetXmlAttribute(ComercioExteriorElement, 'Incoterm'), 'Incoterm is incorrect.');
        Assert.AreEqual('20.000000', GetXmlAttribute(ComercioExteriorElement, 'TipoCambioUSD'), 'TipoCambioUSD is incorrect.');
        Assert.AreEqual('10.00', GetXmlAttribute(ComercioExteriorElement, 'TotalUSD'), 'TotalUSD must be the line amount converted to USD.');

        // [THEN] The goods carry the customs data and the USD values
        MercanciaElement := SelectElement(Document, '//cce20:Mercancia');
        Assert.AreEqual(TariffNoTxt, GetXmlAttribute(MercanciaElement, 'FraccionArancelaria'), 'FraccionArancelaria is incorrect.');
        Assert.AreEqual(CustomsUnitTxt, GetXmlAttribute(MercanciaElement, 'UnidadAduana'), 'UnidadAduana is incorrect.');
        Assert.AreEqual('5.000000', GetXmlAttribute(MercanciaElement, 'ValorUnitarioAduana'), 'ValorUnitarioAduana must be the unit price converted to USD.');
        Assert.AreEqual('10.0000', GetXmlAttribute(MercanciaElement, 'ValorDolares'), 'ValorDolares must be the line amount converted to USD.');
    end;

    [Test]
    procedure LocationsUseTransitStartAndTransitHours()
    var
        SalesShipmentHeader: Record "Sales Header";
        Document: XmlDocument;
        ExpectedDate: Text;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] The origin uses the transit start date/time and the destination adds the transit hours to it
        Initialize();

        // [GIVEN] A sales order leaving at 08:00 with 2 transit hours
        CreateSalesShipment(SalesShipmentHeader, false, '');

        // [WHEN] The order is exported as Carta Porte
        Document := ExportCartaPorteDocument(SalesShipmentHeader);

        // [THEN] The origin leaves at 08:00 and the destination is reached at 10:00
        ExpectedDate := Format(WorkDate(), 0, '<Year4>-<Month,2>-<Day,2>');
        Assert.AreEqual(
            ExpectedDate + 'T08:00:00',
            GetXmlAttribute(SelectElement(Document, '//cartaporte31:Ubicacion[@TipoUbicacion="Origen"]'), 'FechaHoraSalidaLlegada'),
            'The origin date/time must be the transit start.');
        Assert.AreEqual(
            ExpectedDate + 'T10:00:00',
            GetXmlAttribute(SelectElement(Document, '//cartaporte31:Ubicacion[@TipoUbicacion="Destino"]'), 'FechaHoraSalidaLlegada'),
            'The destination date/time must be the transit start plus the transit hours.');
    end;

    [Test]
    procedure ShipmentExportIncludesCartaPorteTransitSettings()
    var
        SalesShipmentHeader: Record "Sales Header";
        Document: XmlDocument;
        CartaPorteElement: XmlElement;
        ExpectedDate: Text;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] A sales order exports the Carta Porte transit configuration with the configured transport type and transit time
        Initialize();

        // [GIVEN] An international sales order with the standard transit values required for Carta Porte export
        CreateSalesShipment(SalesShipmentHeader, true, '01');
        SetInternationalShipmentData(SalesShipmentHeader);

        // [WHEN] The order is exported as Carta Porte
        Document := ExportCartaPorteDocument(SalesShipmentHeader);
        CartaPorteElement := SelectElement(Document, '//cartaporte31:CartaPorte');

        // [THEN] The Carta Porte header uses the valid transit values and configured transport type
        Assert.AreEqual('01', GetXmlAttribute(CartaPorteElement, 'ViaEntradaSalida'), 'ViaEntradaSalida must match the configured SAT transport type.');
        ExpectedDate := Format(WorkDate(), 0, '<Year4>-<Month,2>-<Day,2>');
        Assert.AreEqual(
            ExpectedDate + 'T08:00:00',
            GetXmlAttribute(SelectElement(Document, '//cartaporte31:Ubicacion[@TipoUbicacion="Origen"]'), 'FechaHoraSalidaLlegada'),
            'The origin transit start must be the default shipment date/time.');
        Assert.AreEqual(
            ExpectedDate + 'T10:00:00',
            GetXmlAttribute(SelectElement(Document, '//cartaporte31:Ubicacion[@TipoUbicacion="Destino"]'), 'FechaHoraSalidaLlegada'),
            'The destination transit end must reflect the default 2-hour transit window.');
    end;

    local procedure Initialize()
    var
        CompanyInformation: Record "Company Information";
        EDocumentService: Record "E-Document Service";
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        if BindSubscription(this) then;
        EDocumentService.DeleteAll();
        DocumentSendingProfile.DeleteAll();
        CompanyInformation.Get();
        CompanyInformation.Validate("RFC Number", 'MME910620Q85');
        CompanyInformation.Modify();
    end;

    local procedure CreateSalesShipment(var SalesShipmentHeader: Record "Sales Header"; ForeignTrade: Boolean; SATTransportType: Code[10])
    var
        SalesShipmentLine: Record "Sales Line";
        Customer: Record Customer;
        Item: Record Item;
        Location: Record Location;
        SATAddressId: Integer;
        RFCNo: Text[20];
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Tax Identification Type", Customer."Tax Identification Type"::"Legal Entity");
        Customer.Validate("Country/Region Code", 'MX');
        Customer.Validate(Address, 'Avenida Reforma 100');
        Customer.Validate(City, 'Ciudad de Mexico');
        Customer.Validate("Post Code", '06600');
        RFCNo := LibraryUtility.GenerateGUID();
        while StrLen(RFCNo) < 12 do
            RFCNo += 'A';
        Customer.Validate("RFC No.", CopyStr(DelChr(UpperCase(RFCNo), '=', '-'), 1, 12));
        Customer.Modify(true);

        LibraryInventory.CreateItem(Item);
        Item.Description := 'Carta Porte Item';
        Item.Modify();

        LibraryWarehouse.CreateLocation(Location);
        SATAddressId := CreateSATAddress();
        Location."SAT Address ID" := SATAddressId;
        Location.Modify();
        CreateInventorySetup(Item, Location.Code);

        LibrarySales.CreateSalesHeader(SalesShipmentHeader, "Sales Document Type"::Order, Customer."No.");
        SalesShipmentHeader.Validate("Location Code", Location.Code);
        SalesShipmentHeader.Validate("Document Date", WorkDate());
        SalesShipmentHeader.Validate("Posting Date", WorkDate());
        SalesShipmentHeader.Validate("Shipment Date", WorkDate());
        SalesShipmentHeader.Validate("Order Date", WorkDate());
        SalesShipmentHeader."SAT Address ID" := Location."SAT Address ID";
        SalesShipmentHeader."Ship-to Address" := 'Calle Destino 200';
        SalesShipmentHeader."Transit-from Date/Time" := CreateDateTime(WorkDate(), 080000T);
        SalesShipmentHeader."Transit Hours" := 2;
        SalesShipmentHeader."Transit Distance" := 100;
        SalesShipmentHeader."Foreign Trade" := ForeignTrade;
        SalesShipmentHeader."SAT Transport Type" := SATTransportType;
        SetPostingPaymentData(SalesShipmentHeader);

        LibrarySales.CreateSalesLine(SalesShipmentLine, SalesShipmentHeader, SalesShipmentLine.Type::Item, Item."No.", 1);
        SalesShipmentLine.Validate("Location Code", Location.Code);
        SalesShipmentLine.Validate("Unit Price", 100);
        SalesShipmentLine.Modify(true);
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

    local procedure SetInternationalShipmentData(var SalesShipmentHeader: Record "Sales Header")
    var
        Customer: Record Customer;
        SalesShipmentLine: Record "Sales Line";
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        CountryRegionCode: Code[10];
    begin
        CountryRegionCode := CreateForeignCountry();
        Customer.Get(SalesShipmentHeader."Sell-to Customer No.");
        Customer."RFC No." := ForeignRFCTxt;
        Customer."Country/Region Code" := CountryRegionCode;
        Customer."VAT Registration No." := ForeignVATRegNoTxt;
        Customer.Modify();

        SalesShipmentHeader."Ship-to Country/Region Code" := CountryRegionCode;
        SalesShipmentHeader."SAT Customs Regime" := CustomsRegimeTxt;
        SalesShipmentHeader."SAT Transfer Reason" := TransferReasonTxt;
        SalesShipmentHeader."SAT International Trade Term" := IncotermTxt;
        SalesShipmentHeader."Exchange Rate USD" := 20;
        SalesShipmentHeader.Modify();

        SalesShipmentLine.Get(SalesShipmentHeader."Document Type", SalesShipmentHeader."No.", 10000);
        SalesShipmentLine.Quantity := 2;
        SalesShipmentLine."Unit Price" := 100;
        SalesShipmentLine.Modify();

        Item.Get(SalesShipmentLine."No.");
        Item."Tariff No." := TariffNoTxt;
        Item.Modify();

        UnitOfMeasure.Get(SalesShipmentLine."Unit of Measure Code");
        UnitOfMeasure."SAT Customs Unit" := CustomsUnitTxt;
        UnitOfMeasure.Modify();
    end;

    local procedure CreateForeignCountry(): Code[10]
    var
        CountryRegion: Record "Country/Region";
    begin
        CountryRegion.Init();
        CountryRegion.Code := LibraryUtility.GenerateRandomCode(CountryRegion.FieldNo(Code), Database::"Country/Region");
        CountryRegion."SAT Country Code" := ForeignSATCountryCodeTxt;
        CountryRegion.Insert();
        exit(CountryRegion.Code);
    end;

    local procedure CreateInventorySetup(var Item: Record Item; LocationCode: Code[10])
    var
        InventoryPostingSetup: Record "Inventory Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        if not InventoryPostingSetup.Get(LocationCode, Item."Inventory Posting Group") then begin
            InventoryPostingSetup.Init();
            InventoryPostingSetup.Validate("Location Code", LocationCode);
            InventoryPostingSetup.Validate("Invt. Posting Group Code", Item."Inventory Posting Group");
            InventoryPostingSetup.Validate("Inventory Account", GLAccount."No.");
            InventoryPostingSetup.Insert(true);
        end;
    end;

    local procedure SetPostingPaymentData(var SalesHeader: Record "Sales Header")
    var
        PaymentMethod: Record 289;
        PaymentTerms: Record 3;
    begin
        if not PaymentMethod.Get('MX-TEST') then begin
            PaymentMethod.Init();
            PaymentMethod.Code := 'MX-TEST';
            PaymentMethod.Description := 'Mexico test payment method';
            PaymentMethod.Insert();
        end;
        SalesHeader.Validate("Payment Method Code", PaymentMethod.Code);
        if not PaymentTerms.FindFirst() then begin
            PaymentTerms.Init();
            PaymentTerms.Code := 'MX-TEST';
            PaymentTerms.Description := 'Mexico test payment terms';
            PaymentTerms.Insert();
        end;
        SalesHeader.Validate("Payment Terms Code", PaymentTerms.Code);
        SalesHeader.Modify(true);
    end;

    local procedure ExportCartaPorte(SalesShipmentHeader: Record "Sales Header"): XmlElement
    begin
        exit(SelectElement(ExportCartaPorteDocument(SalesShipmentHeader), '//cartaporte31:CartaPorte'));
    end;

    local procedure ExportCartaPorteDocument(SalesShipmentHeader: Record "Sales Header") Document: XmlDocument
    var
        SalesShipmentLine: Record "Sales Line";
        EDocument: Record "E-Document";
        TempBlob: Codeunit "Temp Blob";
        SourceHeader: RecordRef;
        SourceLines: RecordRef;
        InStream: InStream;
    begin
        SalesShipmentHeader.SetRecFilter();
        SourceHeader.GetTable(SalesShipmentHeader);
        SalesShipmentLine.SetRange("Document Type", SalesShipmentHeader."Document Type");
        SalesShipmentLine.SetRange("Document No.", SalesShipmentHeader."No.");
        SourceLines.GetTable(SalesShipmentLine);

        EDocument := CreateEDocumentForShipment(SalesShipmentHeader.RecordId());
        ExportInterfactura.Export(SourceHeader, SourceLines, EDocument, TempBlob, false);

        TempBlob.CreateInStream(InStream, TextEncoding::UTF8);
        XmlDocument.ReadFrom(InStream, Document);
    end;

    local procedure CreateEDocumentForShipment(DocumentRecordId: RecordId): Record "E-Document"
    var
        EDocument: Record "E-Document";
        EDocumentService: Record "E-Document Service";
        EDocExport: Codeunit "E-Doc. Export";
        SourceHeader: RecordRef;
    begin
        CreateCFDIService(EDocumentService);
        SourceHeader.Open(DocumentRecordId.TableNo());
        SourceHeader.Get(DocumentRecordId);
        Assert.IsTrue(EDocExport.CreateEDocument(EDocument, SourceHeader, EDocumentService, "E-Document Type"::"Sales Order"), 'The E-Document was not created for the source order.');
        EDocument.Reset();
        EDocument.SetRange("Document Record ID", DocumentRecordId);
        EDocument.FindFirst();
        exit(EDocument);
    end;

    local procedure CreateCFDIService(var EDocumentService: Record "E-Document Service")
    var
        DocSendingProfile: Record "Document Sending Profile";
    begin
        if not EDocumentService.Get(CFDIServiceCodeTok) then begin
            if not DocSendingProfile.Get(CFDIServiceCodeTok) then begin
                DocSendingProfile.Init();
                DocSendingProfile.Code := CFDIServiceCodeTok;
                DocSendingProfile.Description := 'CFDI Test Profile';
                DocSendingProfile.Default := true;
                DocSendingProfile.Insert();
            end;
            EDocumentService.Init();
            EDocumentService.Code := CFDIServiceCodeTok;
            EDocumentService.Insert();
            EDocumentService.Validate("Document Format", EDocumentService."Document Format"::CFDI);
            EDocumentService.Modify();
        end;
        EDocumentService.SetRecFilter();
    end;

    local procedure SelectElement(Document: XmlDocument; XPath: Text): XmlElement
    var
        FoundNode: XmlNode;
    begin
        Assert.IsTrue(Document.SelectSingleNode(XPath, GetNamespaceManager(Document), FoundNode), StrSubstNo(NodeMissingErr, XPath));
        exit(FoundNode.AsXmlElement());
    end;

    local procedure NodeExists(Document: XmlDocument; XPath: Text): Boolean
    var
        FoundNode: XmlNode;
    begin
        exit(Document.SelectSingleNode(XPath, GetNamespaceManager(Document), FoundNode));
    end;

    local procedure GetNamespaceManager(Document: XmlDocument) NamespaceManager: XmlNamespaceManager
    begin
        NamespaceManager.NameTable(Document.NameTable());
        NamespaceManager.AddNamespace('cartaporte31', CartaPorteNamespaceTxt);
        NamespaceManager.AddNamespace('cce20', ComercioExteriorNamespaceTxt);
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
