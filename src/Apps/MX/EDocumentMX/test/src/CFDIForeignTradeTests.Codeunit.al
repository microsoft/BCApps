// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Interfactura.Tests;

using Microsoft.EServices.EDocument.Interfactura;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Sales.Customer;
using Microsoft.Sales.History;
using Microsoft.eServices.EDocument;
using System.Utilities;

codeunit 148758 "CFDI Foreign Trade Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;
    Permissions = tabledata "Sales Invoice Header" = rimd,
                  tabledata "Sales Invoice Line" = rimd,
                  tabledata "Company Information" = rm,
                  tabledata "Country/Region" = rimd,
                  tabledata Customer = rimd,
                  tabledata Item = rimd,
                  tabledata Location = rimd,
                  tabledata "Unit of Measure" = rimd,
                  tabledata "SAT Address" = rimd,
                  tabledata "SAT Suburb" = rimd;

    var
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        ExportInterfactura: Codeunit "Export Interfactura MX";
        LoggedErrors: Text;
        CFDINamespaceTxt: Label 'http://www.sat.gob.mx/cfd/4', Locked = true;
        ComercioExteriorNamespaceTxt: Label 'http://www.sat.gob.mx/ComercioExterior20', Locked = true;
        ForeignRFCTxt: Label 'XEXX010101000', Locked = true;
        ForeignVATRegNoTxt: Label '123456789', Locked = true;
        ForeignSATCountryCodeTxt: Label 'USA', Locked = true;
        IncotermTxt: Label 'FOB', Locked = true;
        TariffNoTxt: Label '84713001', Locked = true;
        CustomsUnitTxt: Label '06', Locked = true;
        CertificateOfOriginTxt: Label 'CO-2024-001', Locked = true;
        NodeMissingErr: Label 'The node %1 is missing from the exported XML.', Comment = '%1 = XPath of the node', Locked = true;
        FieldErrorMissingErr: Label 'The validation did not report the missing field %1.', Comment = '%1 = field caption', Locked = true;

    [Test]
    procedure ForeignTradeInvoiceExportsComercioExteriorComplement()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Document: XmlDocument;
        ComercioExteriorElement: XmlElement;
        MercanciaElement: XmlElement;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] A foreign trade invoice exports the ComercioExterior complement with the Incoterm, USD exchange rate and USD total
        Initialize();

        // [GIVEN] A posted foreign trade invoice of 200 MXN with a USD exchange rate of 20
        CreateForeignTradeInvoice(SalesInvoiceHeader, 20, 200, 0, 0);

        // [WHEN] The invoice is exported
        Document := ExportInvoice(SalesInvoiceHeader);

        // [THEN] The ComercioExterior complement carries the header data converted to USD
        ComercioExteriorElement := SelectElement(Document, '//cfdi:Complemento/cce20:ComercioExterior');
        Assert.AreEqual('2.0', GetXmlAttribute(ComercioExteriorElement, 'Version'), 'Version is incorrect.');
        Assert.AreEqual(IncotermTxt, GetXmlAttribute(ComercioExteriorElement, 'Incoterm'), 'Incoterm is incorrect.');
        Assert.AreEqual('20.000000', GetXmlAttribute(ComercioExteriorElement, 'TipoCambioUSD'), 'TipoCambioUSD is incorrect.');
        Assert.AreEqual('10.00', GetXmlAttribute(ComercioExteriorElement, 'TotalUSD'), 'TotalUSD must be the invoice amount converted to USD.');

        // [THEN] The foreign receiver is identified by its tax registration number
        Assert.AreEqual(ForeignVATRegNoTxt, GetXmlAttribute(SelectElement(Document, '//cce20:Receptor'), 'NumRegIdTrib'), 'NumRegIdTrib of the foreign trade receiver is incorrect.');

        // [THEN] The goods carry the tariff number, customs unit and USD values
        MercanciaElement := SelectElement(Document, '//cce20:Mercancia');
        Assert.AreEqual(TariffNoTxt, GetXmlAttribute(MercanciaElement, 'FraccionArancelaria'), 'FraccionArancelaria is incorrect.');
        Assert.AreEqual(CustomsUnitTxt, GetXmlAttribute(MercanciaElement, 'UnidadAduana'), 'UnidadAduana is incorrect.');
        Assert.AreEqual('10.000000', GetXmlAttribute(MercanciaElement, 'ValorUnitarioAduana'), 'ValorUnitarioAduana must be the unit amount converted to USD.');
        Assert.AreEqual('10.0000', GetXmlAttribute(MercanciaElement, 'ValorDolares'), 'ValorDolares must be the line amount converted to USD.');
    end;

    [Test]
    procedure ForeignTradeInvoiceValorDolaresAddsUpToTotalUSD()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Document: XmlDocument;
        MercanciaNodes: XmlNodeList;
        MercanciaNode: XmlNode;
        LineValue: Decimal;
        SumOfLines: Decimal;
        TotalUSD: Decimal;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] When the USD conversion of each line has to be rounded, the last line absorbs the difference so the lines add up to TotalUSD
        Initialize();

        // [GIVEN] A posted foreign trade invoice with 3 lines of 10 MXN and a USD exchange rate of 3
        CreateForeignTradeInvoice(SalesInvoiceHeader, 3, 10, 10, 10);

        // [WHEN] The invoice is exported
        Document := ExportInvoice(SalesInvoiceHeader);

        // [THEN] The first lines are rounded and the last line takes the rounding difference
        Document.SelectNodes('//cce20:Mercancia', GetNamespaceManager(Document), MercanciaNodes);
        Assert.AreEqual(3, MercanciaNodes.Count(), 'One Mercancia node per invoice line is expected.');
        Assert.AreEqual('3.3333', GetXmlAttribute(GetNodeElement(MercanciaNodes, 1), 'ValorDolares'), 'ValorDolares of the first line is incorrect.');
        Assert.AreEqual('3.3333', GetXmlAttribute(GetNodeElement(MercanciaNodes, 2), 'ValorDolares'), 'ValorDolares of the second line is incorrect.');
        Assert.AreEqual('3.3334', GetXmlAttribute(GetNodeElement(MercanciaNodes, 3), 'ValorDolares'), 'ValorDolares of the last line must absorb the rounding difference.');

        // [THEN] The sum of ValorDolares equals TotalUSD
        foreach MercanciaNode in MercanciaNodes do begin
            Evaluate(LineValue, GetXmlAttribute(MercanciaNode.AsXmlElement(), 'ValorDolares'), 9);
            SumOfLines += LineValue;
        end;
        Evaluate(TotalUSD, GetXmlAttribute(SelectElement(Document, '//cce20:ComercioExterior'), 'TotalUSD'), 9);
        Assert.AreEqual(TotalUSD, SumOfLines, 'The sum of ValorDolares must be equal to TotalUSD.');
    end;

    [Test]
    procedure ForeignTradeInvoiceWithCertificateOfOriginExportsCertificateNumber()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ComercioExteriorElement: XmlElement;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] A foreign trade invoice with a certificate of origin exports CertificadoOrigen 1 and the certificate number
        Initialize();

        // [GIVEN] A posted foreign trade invoice with a certificate of origin number
        CreateForeignTradeInvoice(SalesInvoiceHeader, 20, 200, 0, 0);
        SalesInvoiceHeader."CFDI Certificate of Origin No." := CertificateOfOriginTxt;
        SalesInvoiceHeader.Modify();

        // [WHEN] The invoice is exported
        ComercioExteriorElement := SelectElement(ExportInvoice(SalesInvoiceHeader), '//cce20:ComercioExterior');

        // [THEN] The certificate of origin is reported
        Assert.AreEqual('1', GetXmlAttribute(ComercioExteriorElement, 'CertificadoOrigen'), 'CertificadoOrigen must be 1 when a certificate of origin exists.');
        Assert.AreEqual(CertificateOfOriginTxt, GetXmlAttribute(ComercioExteriorElement, 'NumCertificadoOrigen'), 'NumCertificadoOrigen is incorrect.');
    end;

    [Test]
    procedure ForeignTradeInvoiceWithoutCertificateOfOriginExportsZero()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ComercioExteriorElement: XmlElement;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] A foreign trade invoice without a certificate of origin exports CertificadoOrigen 0 and no certificate number
        Initialize();

        // [GIVEN] A posted foreign trade invoice without a certificate of origin number
        CreateForeignTradeInvoice(SalesInvoiceHeader, 20, 200, 0, 0);

        // [WHEN] The invoice is exported
        ComercioExteriorElement := SelectElement(ExportInvoice(SalesInvoiceHeader), '//cce20:ComercioExterior');

        // [THEN] No certificate of origin is reported
        Assert.AreEqual('0', GetXmlAttribute(ComercioExteriorElement, 'CertificadoOrigen'), 'CertificadoOrigen must be 0 without a certificate of origin.');
        Assert.AreEqual('', GetXmlAttribute(ComercioExteriorElement, 'NumCertificadoOrigen'), 'NumCertificadoOrigen must not be exported without a certificate of origin.');
    end;

    [Test]
    procedure ForeignCustomerReceptorExportsFiscalResidenceAndTaxId()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ReceptorElement: XmlElement;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] A foreign customer with the generic foreign RFC exports ResidenciaFiscal and NumRegIdTrib in cfdi:Receptor
        Initialize();

        // [GIVEN] A posted invoice for a customer with RFC XEXX010101000, a foreign country and a tax registration number
        CreateForeignTradeInvoice(SalesInvoiceHeader, 20, 200, 0, 0);

        // [WHEN] The invoice is exported
        ReceptorElement := SelectElement(ExportInvoice(SalesInvoiceHeader), '/cfdi:Comprobante/cfdi:Receptor');

        // [THEN] The receiver carries the SAT country code and the tax registration number
        Assert.AreEqual(ForeignRFCTxt, GetXmlAttribute(ReceptorElement, 'Rfc'), 'Rfc is incorrect.');
        Assert.AreEqual(ForeignSATCountryCodeTxt, GetXmlAttribute(ReceptorElement, 'ResidenciaFiscal'), 'ResidenciaFiscal must be the SAT code of the customer country.');
        Assert.AreEqual(ForeignVATRegNoTxt, GetXmlAttribute(ReceptorElement, 'NumRegIdTrib'), 'NumRegIdTrib must be the customer tax registration number.');
    end;

    [Test]
    procedure ForeignCustomerWithoutTaxIdOmitsForeignReceptorAttributes()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Customer: Record Customer;
        ReceptorElement: XmlElement;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] A foreign customer without a tax registration number does not export ResidenciaFiscal nor NumRegIdTrib in cfdi:Receptor
        Initialize();

        // [GIVEN] A posted invoice for a foreign customer without a tax registration number
        CreateForeignTradeInvoice(SalesInvoiceHeader, 20, 200, 0, 0);
        Customer.Get(SalesInvoiceHeader."Bill-to Customer No.");
        Customer."VAT Registration No." := '';
        Customer.Modify();

        // [WHEN] The invoice is exported
        ReceptorElement := SelectElement(ExportInvoice(SalesInvoiceHeader), '/cfdi:Comprobante/cfdi:Receptor');

        // [THEN] The foreign tax attributes are not exported
        Assert.AreEqual('', GetXmlAttribute(ReceptorElement, 'ResidenciaFiscal'), 'ResidenciaFiscal must not be exported without a tax registration number.');
        Assert.AreEqual('', GetXmlAttribute(ReceptorElement, 'NumRegIdTrib'), 'NumRegIdTrib must not be exported without a tax registration number.');
    end;

    [Test]
    procedure DomesticInvoiceDoesNotExportComercioExterior()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Document: XmlDocument;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] An invoice without foreign trade does not export the Complemento nor the ComercioExterior node
        Initialize();

        // [GIVEN] A posted invoice without foreign trade
        CreateForeignTradeInvoice(SalesInvoiceHeader, 20, 200, 0, 0);
        SalesInvoiceHeader."Foreign Trade" := false;
        SalesInvoiceHeader.Modify();

        // [WHEN] The invoice is exported
        Document := ExportInvoice(SalesInvoiceHeader);

        // [THEN] No foreign trade complement is exported
        Assert.IsFalse(NodeExists(Document, '//cfdi:Complemento'), 'Complemento must not be exported for a domestic invoice.');
        Assert.IsFalse(NodeExists(Document, '//cce20:ComercioExterior'), 'ComercioExterior must not be exported for a domestic invoice.');
    end;

    [Test]
    [HandlerFunctions('ErrorMessagesCollectHandler')]
    procedure ForeignTradeInvoiceValidationRequiresIncotermAndUSDExchangeRate()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Validation: Codeunit "EDoc CFDI Validation MX";
        SourceHeader: RecordRef;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] Validation of a foreign trade invoice reports the missing Incoterm and USD exchange rate
        Initialize();

        // [GIVEN] A posted foreign trade invoice without Incoterm and without USD exchange rate
        CreateForeignTradeInvoice(SalesInvoiceHeader, 20, 200, 0, 0);
        SalesInvoiceHeader."SAT International Trade Term" := '';
        SalesInvoiceHeader."Exchange Rate USD" := 0;
        SalesInvoiceHeader.Modify();
        SourceHeader.GetTable(SalesInvoiceHeader);

        // [WHEN] The invoice is validated
        asserterror Validation.CheckSalesDocument(SourceHeader);

        // [THEN] Both missing fields are reported
        VerifyErrorLoggedForField(SalesInvoiceHeader.FieldCaption("SAT International Trade Term"));
        VerifyErrorLoggedForField(SalesInvoiceHeader.FieldCaption("Exchange Rate USD"));
    end;

    [Test]
    [HandlerFunctions('ErrorMessagesCollectHandler')]
    procedure ForeignTradeInvoiceValidationRequiresTariffNoAndCustomsUnit()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        Validation: Codeunit "EDoc CFDI Validation MX";
        SourceHeader: RecordRef;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] Validation of a foreign trade invoice reports goods without tariff number and units without customs unit
        Initialize();

        // [GIVEN] A posted foreign trade invoice whose item has no tariff number and whose unit of measure has no customs unit
        CreateForeignTradeInvoice(SalesInvoiceHeader, 20, 200, 0, 0);
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.FindFirst();
        Item.Get(SalesInvoiceLine."No.");
        Item."Tariff No." := '';
        Item.Modify();
        UnitOfMeasure.Get(SalesInvoiceLine."Unit of Measure Code");
        UnitOfMeasure."SAT Customs Unit" := '';
        UnitOfMeasure.Modify();
        SourceHeader.GetTable(SalesInvoiceHeader);

        // [WHEN] The invoice is validated
        asserterror Validation.CheckSalesDocument(SourceHeader);

        // [THEN] Both missing fields are reported
        VerifyErrorLoggedForField(Item.FieldCaption("Tariff No."));
        VerifyErrorLoggedForField(UnitOfMeasure.FieldCaption("SAT Customs Unit"));
    end;

    local procedure Initialize()
    var
        CompanyInformation: Record "Company Information";
    begin
        if BindSubscription(this) then;
        LoggedErrors := '';
        CompanyInformation.Get();
        CompanyInformation."RFC Number" := 'MME910620Q85';
        CompanyInformation.Modify();
    end;

    local procedure CreateForeignTradeInvoice(var SalesInvoiceHeader: Record "Sales Invoice Header"; ExchangeRateUSD: Decimal; LineAmount1: Decimal; LineAmount2: Decimal; LineAmount3: Decimal)
    var
        Customer: Record Customer;
        Item: Record Item;
        Location: Record Location;
        UnitOfMeasure: Record "Unit of Measure";
    begin
        CreateForeignCustomer(Customer);
        CreateLocation(Location);
        CreateUnitOfMeasure(UnitOfMeasure);
        CreateItem(Item);

        SalesInvoiceHeader.Init();
        SalesInvoiceHeader."No." := LibraryUtility.GenerateRandomCode(SalesInvoiceHeader.FieldNo("No."), Database::"Sales Invoice Header");
        SalesInvoiceHeader."Sell-to Customer No." := Customer."No.";
        SalesInvoiceHeader."Bill-to Customer No." := Customer."No.";
        SalesInvoiceHeader."Bill-to Name" := Customer.Name;
        SalesInvoiceHeader."Bill-to Address" := 'Main Street 1';
        SalesInvoiceHeader."Bill-to Post Code" := '10001';
        SalesInvoiceHeader."Document Date" := WorkDate();
        SalesInvoiceHeader."Posting Date" := WorkDate();
        SalesInvoiceHeader."Location Code" := Location.Code;
        SalesInvoiceHeader."SAT Address ID" := Location."SAT Address ID";
        SalesInvoiceHeader."CFDI Purpose" := 'S01';
        SalesInvoiceHeader."CFDI Export Code" := '02';
        SalesInvoiceHeader."Foreign Trade" := true;
        SalesInvoiceHeader."SAT International Trade Term" := IncotermTxt;
        SalesInvoiceHeader."Exchange Rate USD" := ExchangeRateUSD;
        SalesInvoiceHeader.Insert();

        CreateInvoiceLine(SalesInvoiceHeader, 10000, Item, UnitOfMeasure, LineAmount1);
        CreateInvoiceLine(SalesInvoiceHeader, 20000, Item, UnitOfMeasure, LineAmount2);
        CreateInvoiceLine(SalesInvoiceHeader, 30000, Item, UnitOfMeasure, LineAmount3);
    end;

    local procedure CreateInvoiceLine(SalesInvoiceHeader: Record "Sales Invoice Header"; LineNo: Integer; Item: Record Item; UnitOfMeasure: Record "Unit of Measure"; LineAmount: Decimal)
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        if LineAmount = 0 then
            exit;

        SalesInvoiceLine.Init();
        SalesInvoiceLine."Document No." := SalesInvoiceHeader."No.";
        SalesInvoiceLine."Line No." := LineNo;
        SalesInvoiceLine."Sell-to Customer No." := SalesInvoiceHeader."Sell-to Customer No.";
        SalesInvoiceLine."Bill-to Customer No." := SalesInvoiceHeader."Bill-to Customer No.";
        SalesInvoiceLine.Type := SalesInvoiceLine.Type::Item;
        SalesInvoiceLine."No." := Item."No.";
        SalesInvoiceLine.Description := Item.Description;
        SalesInvoiceLine."Location Code" := SalesInvoiceHeader."Location Code";
        SalesInvoiceLine."Unit of Measure Code" := UnitOfMeasure.Code;
        SalesInvoiceLine.Quantity := 1;
        SalesInvoiceLine."Unit Price" := LineAmount;
        SalesInvoiceLine.Amount := LineAmount;
        SalesInvoiceLine."Amount Including VAT" := LineAmount;
        SalesInvoiceLine.Insert();
    end;

    local procedure CreateForeignCustomer(var Customer: Record Customer)
    var
        CountryRegion: Record "Country/Region";
    begin
        CountryRegion.Init();
        CountryRegion.Code := LibraryUtility.GenerateRandomCode(CountryRegion.FieldNo(Code), Database::"Country/Region");
        CountryRegion."SAT Country Code" := ForeignSATCountryCodeTxt;
        CountryRegion.Insert();

        Customer.Init();
        Customer."No." := LibraryUtility.GenerateRandomCode(Customer.FieldNo("No."), Database::Customer);
        Customer.Name := 'Foreign Trade Customer';
        Customer."RFC No." := ForeignRFCTxt;
        Customer."Country/Region Code" := CountryRegion.Code;
        Customer."VAT Registration No." := ForeignVATRegNoTxt;
        Customer."SAT Tax Regime Classification" := '616';
        Customer.Insert();
    end;

    local procedure CreateLocation(var Location: Record Location)
    begin
        Location.Init();
        Location.Code := LibraryUtility.GenerateRandomCode(Location.FieldNo(Code), Database::Location);
        Location.Address := 'Avenida Reforma 100';
        Location."SAT Address ID" := CreateSATAddress();
        Location.Insert();
    end;

    local procedure CreateUnitOfMeasure(var UnitOfMeasure: Record "Unit of Measure")
    begin
        UnitOfMeasure.Init();
        UnitOfMeasure.Code := LibraryUtility.GenerateRandomCode(UnitOfMeasure.FieldNo(Code), Database::"Unit of Measure");
        UnitOfMeasure."SAT UofM Classification" := 'H87';
        UnitOfMeasure."SAT Customs Unit" := CustomsUnitTxt;
        UnitOfMeasure.Insert();
    end;

    local procedure CreateItem(var Item: Record Item)
    begin
        Item.Init();
        Item."No." := LibraryUtility.GenerateRandomCode(Item.FieldNo("No."), Database::Item);
        Item.Description := 'Foreign Trade Item';
        Item."Tariff No." := TariffNoTxt;
        Item.Insert();
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

    local procedure ExportInvoice(SalesInvoiceHeader: Record "Sales Invoice Header") Document: XmlDocument
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        EDocument: Record "E-Document";
        TempBlob: Codeunit "Temp Blob";
        SourceHeader: RecordRef;
        SourceLines: RecordRef;
        InStream: InStream;
    begin
        SalesInvoiceHeader.SetRecFilter();
        SourceHeader.GetTable(SalesInvoiceHeader);
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SourceLines.GetTable(SalesInvoiceLine);

        ExportInterfactura.Export(SourceHeader, SourceLines, EDocument, TempBlob, false);

        TempBlob.CreateInStream(InStream, TextEncoding::UTF8);
        XmlDocument.ReadFrom(InStream, Document);
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
        NamespaceManager.AddNamespace('cfdi', CFDINamespaceTxt);
        NamespaceManager.AddNamespace('cce20', ComercioExteriorNamespaceTxt);
    end;

    local procedure GetNodeElement(NodeList: XmlNodeList; Index: Integer): XmlElement
    var
        Node: XmlNode;
    begin
        NodeList.Get(Index, Node);
        exit(Node.AsXmlElement());
    end;

    local procedure GetXmlAttribute(Element: XmlElement; AttributeName: Text): Text
    var
        Attribute: XmlAttribute;
    begin
        if Element.Attributes().Get(AttributeName, Attribute) then
            exit(Attribute.Value());
        exit('');
    end;

    local procedure VerifyErrorLoggedForField(FieldCaption: Text)
    begin
        Assert.IsTrue(LoggedErrors.Contains(FieldCaption), StrSubstNo(FieldErrorMissingErr, FieldCaption));
    end;

    [PageHandler]
    procedure ErrorMessagesCollectHandler(var ErrorMessages: TestPage "Error Messages")
    begin
        if ErrorMessages.First() then
            repeat
                LoggedErrors += ErrorMessages.Description.Value() + '|';
            until not ErrorMessages.Next();
        ErrorMessages.Close();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Digital Sign MX", 'OnBeforeCreateDigitalSignature', '', false, false)]
    local procedure MockCreateDigitalSignature(OriginalString: Text; SetupId: Code[10]; var SignedString: Text; var IsHandled: Boolean)
    begin
        SignedString := 'TEST-SELLO';
        IsHandled := true;
    end;
}
