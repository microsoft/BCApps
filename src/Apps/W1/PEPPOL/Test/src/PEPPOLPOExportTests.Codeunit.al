// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol.Test;

using Microsoft.Foundation.Company;
using Microsoft.Peppol;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using System.Utilities;

codeunit 139238 "PEPPOL PO Export Tests"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [PEPPOL] [Purchase Order] [Export]
    end;

    var
        Assert: Codeunit Assert;
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        IsInitialized: Boolean;

    [Test]
    procedure ExportXml_PEPPOL_PurchaseOrder_GeneralInfoAndLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        TempBlob: Codeunit "Temp Blob";
        Quantity: Decimal;
        UnitCost: Decimal;
    begin
        // [SCENARIO] Export an unposted Purchase Order to PEPPOL 3.0 Order XML
        // [SCENARIO] and verify the general header identifiers, party info and a single order line are produced.
        Initialize();

        // [GIVEN] A vendor identified by GLN, and a Purchase Order with one item line
        CreateVendorWithAddressAndGLN(Vendor);
        Quantity := LibraryRandom.RandIntInRange(2, 10);
        UnitCost := LibraryRandom.RandDecInRange(10, 100, 2);
        CreatePurchaseOrderWithItemLine(PurchaseHeader, PurchaseLine, Vendor."No.", Quantity, UnitCost);
        PurchaseHeader.Validate("Vendor Order No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Validate("Your Reference", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);

        // [WHEN] The Purchase Order is exported with the PEPPOL 3.0 Purchase format
        ExportPurchaseOrderToBlob(PurchaseHeader, TempBlob);

        // [THEN] The PEPPOL Ordering 3.0 identifiers, order id, issue date, sales order id and buyer reference are exported
        InitXPathXMLReaderForOrder(TempBlob);
        LibraryXPathXMLReader.VerifyNodeValueByXPath('//cbc:CustomizationID', 'urn:fdc:peppol.eu:poacc:trns:order:3');
        LibraryXPathXMLReader.VerifyNodeValueByXPath('//cbc:ProfileID', 'urn:fdc:peppol.eu:poacc:bis:ordering:3');
        LibraryXPathXMLReader.VerifyNodeValueByXPath('//cbc:ID', PurchaseHeader."No.");
        LibraryXPathXMLReader.VerifyNodeValueByXPath('//cbc:IssueDate', Format(PurchaseHeader."Document Date", 0, 9));
        LibraryXPathXMLReader.VerifyNodeValueByXPath('//cbc:SalesOrderID', PurchaseHeader."Vendor Order No.");
        LibraryXPathXMLReader.VerifyNodeValueByXPath('//cbc:CustomerReference', PurchaseHeader."Your Reference");

        // [THEN] <SellerSupplierParty> has <EndpointID> = vendor's GLN with GLN schemeID
        LibraryXPathXMLReader.VerifyNodeValueByXPath('cac:SellerSupplierParty//cbc:EndpointID', Vendor.GLN);
        LibraryXPathXMLReader.VerifyAttributeValue('cac:SellerSupplierParty//cbc:EndpointID', 'schemeID', GetGLNSchemeID());
        LibraryXPathXMLReader.VerifyNodeValueByXPath('cac:SellerSupplierParty//cac:PartyIdentification/cbc:ID', Vendor."No.");

        // [THEN] Exactly one <OrderLine> is created for the single purchase line, with quantity and price
        LibraryXPathXMLReader.VerifyNodeCountByXPath('cac:OrderLine', 1);
        LibraryXPathXMLReader.VerifyNodeValueByXPath('cac:OrderLine/cac:LineItem/cbc:Quantity', Format(Quantity, 0, 9));
        LibraryXPathXMLReader.VerifyNodeValueByXPath('cac:OrderLine/cac:LineItem/cac:Price/cbc:PriceAmount', Format(UnitCost, 0, 9));

        // [THEN] <AnticipatedMonetaryTotal>/<PayableAmount> equals the purchase line's own Amount Including VAT
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        LibraryXPathXMLReader.VerifyNodeValueByXPath('//cac:AnticipatedMonetaryTotal/cbc:PayableAmount', Format(PurchaseLine."Amount Including VAT", 0, 9));
    end;

    [Test]
    procedure ExportXml_PEPPOL_PurchaseOrder_RequestedDeliveryPeriod_HeaderAndLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        Vendor: Record Vendor;
        TempBlob: Codeunit "Temp Blob";
        HeaderRequestedReceiptDate: Date;
        Line1RequestedReceiptDate: Date;
    begin
        // [SCENARIO] Export a Purchase Order where the header has a Requested Receipt Date (which Business Central
        // [SCENARIO] propagates to all lines by default) and the first line is then given its own, different date.
        // [SCENARIO] Each line must export its own Requested Receipt Date, not the header's.
        Initialize();

        // [GIVEN] A Purchase Order with two item lines
        CreateVendorWithAddressAndGLN(Vendor);
        CreatePurchaseOrderWithItemLine(PurchaseHeader, PurchaseLine, Vendor."No.", LibraryRandom.RandIntInRange(1, 5), LibraryRandom.RandDecInRange(10, 100, 2));
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine2, PurchaseHeader, PurchaseLine2.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandIntInRange(1, 5));
        PurchaseLine2.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 100, 2));
        PurchaseLine2.Modify(true);

        // [GIVEN] The header's Requested Receipt Date is set, which Business Central propagates to both lines
        HeaderRequestedReceiptDate := CalcDate('<10D>', WorkDate());
        Line1RequestedReceiptDate := CalcDate('<20D>', WorkDate());
        PurchaseHeader.Validate("Requested Receipt Date", HeaderRequestedReceiptDate);
        PurchaseHeader.Modify(true);

        // [GIVEN] Line 1 is then given its own, different Requested Receipt Date; line 2 keeps the propagated header date
        PurchaseLine.Validate("Requested Receipt Date", Line1RequestedReceiptDate);
        PurchaseLine.Modify(true);

        // [WHEN] The Purchase Order is exported with the PEPPOL 3.0 Purchase format
        ExportPurchaseOrderToBlob(PurchaseHeader, TempBlob);

        // [THEN] The header-level <Delivery><RequestedDeliveryPeriod> uses the header's own Requested Receipt Date
        InitXPathXMLReaderForOrder(TempBlob);
        LibraryXPathXMLReader.VerifyNodeValueByXPath('cac:Delivery/cac:RequestedDeliveryPeriod/cbc:StartDate', Format(HeaderRequestedReceiptDate, 0, 9));
        LibraryXPathXMLReader.VerifyNodeValueByXPath('cac:Delivery/cac:RequestedDeliveryPeriod/cbc:EndDate', Format(HeaderRequestedReceiptDate, 0, 9));

        // [THEN] Line 1's <Delivery><RequestedDeliveryPeriod> uses its own Requested Receipt Date, not the header's
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(
          'cac:OrderLine/cac:LineItem/cac:Delivery/cac:RequestedDeliveryPeriod/cbc:StartDate', Format(Line1RequestedReceiptDate, 0, 9), 0);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(
          'cac:OrderLine/cac:LineItem/cac:Delivery/cac:RequestedDeliveryPeriod/cbc:EndDate', Format(Line1RequestedReceiptDate, 0, 9), 0);

        // [THEN] Line 2 exports the header's Requested Receipt Date, which it inherited and never overrode
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(
          'cac:OrderLine/cac:LineItem/cac:Delivery/cac:RequestedDeliveryPeriod/cbc:StartDate', Format(HeaderRequestedReceiptDate, 0, 9), 1);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(
          'cac:OrderLine/cac:LineItem/cac:Delivery/cac:RequestedDeliveryPeriod/cbc:EndDate', Format(HeaderRequestedReceiptDate, 0, 9), 1);

        // [THEN] Both lines get a <Delivery> block
        LibraryXPathXMLReader.VerifyNodeCountByXPath('cac:OrderLine/cac:LineItem/cac:Delivery', 2);
    end;

    [Test]
    procedure ExportXml_PEPPOL_PurchaseOrder_RequestedDeliveryPeriod_NotSet()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        TempBlob: Codeunit "Temp Blob";
    begin
        // [SCENARIO] Export a Purchase Order whose header and line have no Requested Receipt Date.
        // [SCENARIO] The <RequestedDeliveryPeriod> element must not be exported at all.
        Initialize();

        // [GIVEN] A Purchase Order with one item line and no Requested Receipt Date anywhere
        CreateVendorWithAddressAndGLN(Vendor);
        CreatePurchaseOrderWithItemLine(PurchaseHeader, PurchaseLine, Vendor."No.", LibraryRandom.RandIntInRange(1, 5), LibraryRandom.RandDecInRange(10, 100, 2));
        Assert.AreEqual(0D, PurchaseHeader."Requested Receipt Date", 'Test setup expects a blank header Requested Receipt Date.');
        Assert.AreEqual(0D, PurchaseLine."Requested Receipt Date", 'Test setup expects a blank line Requested Receipt Date.');

        // [WHEN] The Purchase Order is exported with the PEPPOL 3.0 Purchase format
        ExportPurchaseOrderToBlob(PurchaseHeader, TempBlob);

        // [THEN] No <RequestedDeliveryPeriod> element is exported, at header or line level
        InitXPathXMLReaderForOrder(TempBlob);
        LibraryXPathXMLReader.VerifyNodeAbsence('//cac:RequestedDeliveryPeriod');
    end;

    local procedure Initialize()
    var
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"PEPPOL PO Export Tests");
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"PEPPOL PO Export Tests");
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"PEPPOL PO Export Tests");
    end;

    local procedure CreateVendorWithAddressAndGLN(var Vendor: Record Vendor)
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate(Address, LibraryUtility.GenerateGUID());
        Vendor.Validate(City, LibraryUtility.GenerateGUID());
        Vendor.Validate("Country/Region Code", CompanyInformation."Country/Region Code");
        Vendor.Validate(GLN, GetValidGLN());
        Vendor.Modify(true);
    end;

    local procedure CreatePurchaseOrderWithItemLine(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; VendorNo: Code[20]; Quantity: Decimal; UnitCost: Decimal)
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), Quantity);
        PurchaseLine.Validate("Direct Unit Cost", UnitCost);
        PurchaseLine.Modify(true);
    end;

    local procedure ExportPurchaseOrderToBlob(PurchaseHeader: Record "Purchase Header"; var TempBlob: Codeunit "Temp Blob")
    var
        PurchaseOrderExport: Codeunit "Export Purchase Order PEPPOL30";
    begin
        PurchaseOrderExport.SetFormat(Enum::"PEPPOL 3.0 Purchase"::"PEPPOL 3.0 - Purchase");
        PurchaseOrderExport.Run(PurchaseHeader);
        PurchaseOrderExport.GetPurchaseOrderXML(TempBlob);
    end;

    local procedure InitXPathXMLReaderForOrder(TempBlob: Codeunit "Temp Blob")
    var
        OrderNamespaceTxt: Label 'urn:oasis:names:specification:ubl:schema:xsd:Order-2', Locked = true;
    begin
        LibraryXPathXMLReader.InitializeWithBlob(TempBlob, OrderNamespaceTxt);
        LibraryXPathXMLReader.SetDefaultNamespaceUsage(false);
        LibraryXPathXMLReader.AddAdditionalNamespace('cac', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        LibraryXPathXMLReader.AddAdditionalNamespace('cbc', 'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2');
    end;

    local procedure GetGLNSchemeID(): Text
    begin
        exit('0088');
    end;

    local procedure GetValidGLN(): Code[13]
    begin
        exit('0399999000208');
    end;
}
