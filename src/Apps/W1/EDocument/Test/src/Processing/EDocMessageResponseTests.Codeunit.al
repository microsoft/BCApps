// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Test;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Integration;
using Microsoft.EServices.EDocument.Processing;
using Microsoft.EServices.EDocument.Processing.Import.Sales;
using Microsoft.eServices.EDocument.Processing.Message;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Inventory.Item;
using Microsoft.Peppol.Response;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using System.Utilities;

codeunit 139864 "E-Doc. Message Response Tests"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    var
        Customer: Record Customer;
        EDocumentService: Record "E-Document Service";
        Assert: Codeunit Assert;
        LibraryEDoc: Codeunit "Library - E-Document";
        LibraryERM: Codeunit "Library - ERM";
        LibraryLowerPermission: Codeunit "Library - Lower Permissions";
        LibrarySales: Codeunit "Library - Sales";
        IsInitialized: Boolean;
        BuyerOrderNoTxt: Label 'PO-100', Locked = true;
        GLNSchemeIdTxt: Label '0088', Locked = true;
        ItemNameXPathTxt: Label '/resp:OrderResponse/cac:OrderLine/cac:LineItem/cac:Item[cbc:Name=''%1'']', Comment = '%1 = item name', Locked = true;
        LineXPathTxt: Label '/resp:OrderResponse/cac:OrderLine/cac:LineItem[cbc:ID=''%1'']/%2', Comment = '%1 = line id, %2 = relative path', Locked = true;
        NodeMustExistErr: Label 'Node %1 must exist.', Comment = '%1 = XPath', Locked = true;
        OrderLineReferenceXPathTxt: Label '/resp:OrderResponse/cac:OrderLine[cac:LineItem/cbc:ID=''%1'']/cac:OrderLineReference/cbc:LineID', Comment = '%1 = response line id', Locked = true;

    [Test]
    procedure CreateAcknowledgedMessage()
    var
        EDocument: Record "E-Document";
        EDocMessage: Record "E-Document Message";
        EDocMessageMgt: Codeunit "E-Doc. Message Mgt.";
        PEPPOLRespBuilder: Codeunit "PEPPOL Order Resp. Builder";
        TempBlob: Codeunit "Temp Blob";
        MessageEntryNo: Integer;
    begin
        Initialize();
        LibraryEDoc.CreateInboundEDocument(EDocument, EDocumentService);

        PEPPOLRespBuilder.Build(EDocument."Entry No", 'PO-001', 'Seller Corp.', 'Buyer Inc.', 'AB', TempBlob);
        MessageEntryNo := EDocMessageMgt.CreateMessage(EDocument, "E-Document Message Type"::"PEPPOL Order Response", "E-Document Direction"::Incoming, "E-Doc. Response Type"::Acknowledged, TempBlob);

        EDocMessage.Get(MessageEntryNo);
        Assert.AreEqual("E-Doc. Response Type"::Acknowledged, EDocMessage."Response Type", 'Response type must be Acknowledged.');
        Assert.AreEqual("E-Document Message Type"::"PEPPOL Order Response", EDocMessage."Message Type", 'Message type must be PEPPOL Order Response.');
        Assert.AreEqual("E-Document Direction"::Incoming, EDocMessage.Direction, 'Direction must be Incoming.');
        Assert.AreEqual(EDocument."Entry No", EDocMessage."E-Document Entry No.", 'E-Document entry no. must match.');
        Assert.AreEqual("E-Doc. Message Status"::Created, EDocMessage.Status, 'Status must be Created.');
        Assert.IsTrue(EDocMessage."Data Storage Entry No." > 0, 'Data storage entry must be set.');
    end;

    [Test]
    procedure CreateAcceptedMessage()
    var
        EDocument: Record "E-Document";
        EDocMessage: Record "E-Document Message";
        EDocMessageMgt: Codeunit "E-Doc. Message Mgt.";
        PEPPOLRespBuilder: Codeunit "PEPPOL Order Resp. Builder";
        TempBlob: Codeunit "Temp Blob";
        MessageEntryNo: Integer;
    begin
        Initialize();
        LibraryEDoc.CreateInboundEDocument(EDocument, EDocumentService);

        PEPPOLRespBuilder.Build(EDocument."Entry No", 'PO-002', 'Seller Corp.', 'Buyer Inc.', 'AP', TempBlob);
        MessageEntryNo := EDocMessageMgt.CreateMessage(EDocument, "E-Document Message Type"::"PEPPOL Order Response", "E-Document Direction"::Incoming, "E-Doc. Response Type"::Accepted, TempBlob);

        EDocMessage.Get(MessageEntryNo);
        Assert.AreEqual("E-Doc. Response Type"::Accepted, EDocMessage."Response Type", 'Response type must be Accepted.');
        Assert.AreEqual("E-Document Message Type"::"PEPPOL Order Response", EDocMessage."Message Type", 'Message type must be PEPPOL Order Response.');
        Assert.AreEqual("E-Document Direction"::Incoming, EDocMessage.Direction, 'Direction must be Incoming.');
        Assert.AreEqual(EDocument."Entry No", EDocMessage."E-Document Entry No.", 'E-Document entry no. must match.');
        Assert.AreEqual("E-Doc. Message Status"::Created, EDocMessage.Status, 'Status must be Created.');
        Assert.IsTrue(EDocMessage."Data Storage Entry No." > 0, 'Data storage entry must be set.');
    end;

    [Test]
    procedure CreateRejectedMessage()
    var
        EDocument: Record "E-Document";
        EDocMessage: Record "E-Document Message";
        EDocMessageMgt: Codeunit "E-Doc. Message Mgt.";
        PEPPOLRespBuilder: Codeunit "PEPPOL Order Resp. Builder";
        TempBlob: Codeunit "Temp Blob";
        MessageEntryNo: Integer;
    begin
        Initialize();
        LibraryEDoc.CreateInboundEDocument(EDocument, EDocumentService);

        PEPPOLRespBuilder.Build(EDocument."Entry No", 'PO-003', 'Seller Corp.', 'Buyer Inc.', 'RE', TempBlob);
        MessageEntryNo := EDocMessageMgt.CreateMessage(EDocument, "E-Document Message Type"::"PEPPOL Order Response", "E-Document Direction"::Incoming, "E-Doc. Response Type"::Rejected, TempBlob);

        EDocMessage.Get(MessageEntryNo);
        Assert.AreEqual("E-Doc. Response Type"::Rejected, EDocMessage."Response Type", 'Response type must be Rejected.');
        Assert.AreEqual("E-Document Message Type"::"PEPPOL Order Response", EDocMessage."Message Type", 'Message type must be PEPPOL Order Response.');
        Assert.AreEqual("E-Document Direction"::Incoming, EDocMessage.Direction, 'Direction must be Incoming.');
        Assert.AreEqual(EDocument."Entry No", EDocMessage."E-Document Entry No.", 'E-Document entry no. must match.');
        Assert.AreEqual("E-Doc. Message Status"::Created, EDocMessage.Status, 'Status must be Created.');
        Assert.IsTrue(EDocMessage."Data Storage Entry No." > 0, 'Data storage entry must be set.');
    end;

    [Test]
    procedure OrderResponseBuilderWritesT76Structure()
    var
        PEPPOLRespBuilder: Codeunit "PEPPOL Order Resp. Builder";
        TempBlob: Codeunit "Temp Blob";
        XmlDoc: XmlDocument;
        XmlNamespaces: XmlNamespaceManager;
    begin
        // [SCENARIO] The PEPPOL builder writes the elements PEPPOL BIS 28 (T76) requires for a conditionally accepted order.
        Initialize();

        // [WHEN] A response with parties, a promised delivery date and a changed line is built
        PEPPOLRespBuilder.SetHeader('SO-1', 'SO-1', BuyerOrderNoTxt, 'CA', 'EUR', 20260301D);
        PEPPOLRespBuilder.SetSellerParty(SellerEndpointId(), GLNSchemeIdTxt, 'Seller Corp.');
        PEPPOLRespBuilder.SetBuyerParty(BuyerEndpointId(), GLNSchemeIdTxt, 'Buyer Inc.');
        PEPPOLRespBuilder.SetPromisedDeliveryDate(20260320D);
        PEPPOLRespBuilder.AddLine('1', '3', 'Widget A');
        PEPPOLRespBuilder.SetLineQuantity(6, 'EA');
        PEPPOLRespBuilder.SetLineMaximumBackorderQuantity(4);
        PEPPOLRespBuilder.SetLinePromisedDeliveryDate(20260325D);
        PEPPOLRespBuilder.SetLinePrice(12.5);
        PEPPOLRespBuilder.SetLineItemIdentification('B-WIDGET-1', 'WIDGET-A');
        PEPPOLRespBuilder.AddLine('2', '7', '');
        PEPPOLRespBuilder.Build(TempBlob);
        LoadResponse(TempBlob, XmlDoc, XmlNamespaces);

        // [THEN] Header, parties, delivery and lines follow the T76 structure
        Assert.AreEqual('urn:fdc:peppol.eu:poacc:trns:order_response:3', GetValue(XmlDoc, XmlNamespaces, '/resp:OrderResponse/cbc:CustomizationID'), 'CustomizationID');
        Assert.AreEqual('urn:fdc:peppol.eu:poacc:bis:ordering:3', GetValue(XmlDoc, XmlNamespaces, '/resp:OrderResponse/cbc:ProfileID'), 'ProfileID must be the Ordering profile.');
        Assert.AreEqual('SO-1', GetValue(XmlDoc, XmlNamespaces, '/resp:OrderResponse/cbc:ID'), 'ID');
        Assert.AreEqual('2026-03-01', GetValue(XmlDoc, XmlNamespaces, '/resp:OrderResponse/cbc:IssueDate'), 'IssueDate');
        Assert.AreEqual('CA', GetValue(XmlDoc, XmlNamespaces, '/resp:OrderResponse/cbc:OrderResponseCode'), 'OrderResponseCode');
        Assert.AreEqual('EUR', GetValue(XmlDoc, XmlNamespaces, '/resp:OrderResponse/cbc:DocumentCurrencyCode'), 'DocumentCurrencyCode');
        Assert.AreEqual(BuyerOrderNoTxt, GetValue(XmlDoc, XmlNamespaces, '/resp:OrderResponse/cac:OrderReference/cbc:ID'), 'OrderReference ID');
        Assert.AreEqual(SellerEndpointId(), GetValue(XmlDoc, XmlNamespaces, '/resp:OrderResponse/cac:SellerSupplierParty/cac:Party/cbc:EndpointID'), 'Seller EndpointID');
        Assert.AreEqual(GLNSchemeIdTxt, GetValue(XmlDoc, XmlNamespaces, '/resp:OrderResponse/cac:SellerSupplierParty/cac:Party/cbc:EndpointID/@schemeID'), 'Seller EndpointID schemeID');
        Assert.AreEqual(BuyerEndpointId(), GetValue(XmlDoc, XmlNamespaces, '/resp:OrderResponse/cac:BuyerCustomerParty/cac:Party/cbc:EndpointID'), 'Buyer EndpointID');
        Assert.AreEqual(GLNSchemeIdTxt, GetValue(XmlDoc, XmlNamespaces, '/resp:OrderResponse/cac:BuyerCustomerParty/cac:Party/cbc:EndpointID/@schemeID'), 'Buyer EndpointID schemeID');
        Assert.AreEqual('2026-03-20', GetValue(XmlDoc, XmlNamespaces, '/resp:OrderResponse/cac:Delivery/cac:PromisedDeliveryPeriod/cbc:StartDate'), 'Header promised delivery');

        Assert.AreEqual('3', GetLineValue(XmlDoc, XmlNamespaces, '1', 'cbc:LineStatusCode'), 'Line 1 status');
        Assert.AreEqual('6', GetLineValue(XmlDoc, XmlNamespaces, '1', 'cbc:Quantity'), 'Line 1 quantity');
        Assert.AreEqual('EA', GetLineValue(XmlDoc, XmlNamespaces, '1', 'cbc:Quantity/@unitCode'), 'Line 1 unit code');
        Assert.AreEqual('4', GetLineValue(XmlDoc, XmlNamespaces, '1', 'cbc:MaximumBackorderQuantity'), 'Line 1 backorder quantity');
        Assert.AreEqual('2026-03-25', GetLineValue(XmlDoc, XmlNamespaces, '1', 'cac:Delivery/cac:PromisedDeliveryPeriod/cbc:StartDate'), 'Line 1 promised delivery');
        Assert.AreEqual('12.5', GetLineValue(XmlDoc, XmlNamespaces, '1', 'cac:Price/cbc:PriceAmount'), 'Line 1 price');
        Assert.AreEqual('EUR', GetLineValue(XmlDoc, XmlNamespaces, '1', 'cac:Price/cbc:PriceAmount/@currencyID'), 'Line 1 price currency');
        Assert.AreEqual('Widget A', GetLineValue(XmlDoc, XmlNamespaces, '1', 'cac:Item/cbc:Name'), 'Line 1 item name');
        Assert.AreEqual('B-WIDGET-1', GetLineValue(XmlDoc, XmlNamespaces, '1', 'cac:Item/cac:BuyersItemIdentification/cbc:ID'), 'Line 1 buyers item id');
        Assert.AreEqual('WIDGET-A', GetLineValue(XmlDoc, XmlNamespaces, '1', 'cac:Item/cac:SellersItemIdentification/cbc:ID'), 'Line 1 sellers item id');
        Assert.AreEqual('7', GetLineValue(XmlDoc, XmlNamespaces, '2', 'cbc:LineStatusCode'), 'Line 2 status');
        Assert.AreEqual('2', GetLineValue(XmlDoc, XmlNamespaces, '2', 'cac:Item/cbc:Name'), 'Item name is mandatory and falls back to the line id.');
        Assert.AreEqual(0, CountNodes(XmlDoc, XmlNamespaces, '/resp:OrderResponse/cac:OrderLine[2]/cac:LineItem/cac:Item/cac:BuyersItemIdentification'), 'Empty item identifiers must not be written.');
        Assert.AreEqual('2', GetValue(XmlDoc, XmlNamespaces, '/resp:OrderResponse/cac:OrderLine[2]/cac:OrderLineReference/cbc:LineID'), 'Line 2 order line reference');
    end;

    [Test]
    procedure AcceptedOrderWithoutChangesIsReportedAsAccepted()
    var
        EDocument: Record "E-Document";
        GLSetup: Record "General Ledger Setup";
        SalesHeader: Record "Sales Header";
        TempBlob: Codeunit "Temp Blob";
        XmlDoc: XmlDocument;
        XmlNamespaces: XmlNamespaceManager;
        BuiltResponseType: Enum "E-Doc. Response Type";
    begin
        // [SCENARIO] A sales order released exactly as the buyer ordered it is answered with AP and no lines.
        Initialize();

        // [GIVEN] An inbound order with two lines turned into a sales order without changes
        CreateSalesOrderFromInboundOrder(EDocument, SalesHeader);

        // [WHEN] The acceptance response is built
        BuiltResponseType := BuildResponse(EDocument, "E-Doc. Response Type"::Accepted, TempBlob);
        LoadResponse(TempBlob, XmlDoc, XmlNamespaces);

        // [THEN] The response is AP, refers to the sales order and carries both endpoints
        Assert.AreEqual('AP', GetValue(XmlDoc, XmlNamespaces, '/resp:OrderResponse/cbc:OrderResponseCode'), 'An unchanged order must be accepted with AP.');
        Assert.AreEqual("E-Doc. Response Type"::Accepted, BuiltResponseType, 'The message must be stored as Accepted.');
        GLSetup.GetRecordOnce();
        Assert.AreEqual(GLSetup.GetCurrencyCode(''), GetValue(XmlDoc, XmlNamespaces, '/resp:OrderResponse/cbc:DocumentCurrencyCode'), 'A local currency order must state the local currency code.');
        Assert.AreEqual(SalesHeader."No.", GetValue(XmlDoc, XmlNamespaces, '/resp:OrderResponse/cbc:ID'), 'The response ID must be the sales order number.');
        Assert.AreEqual(SalesHeader."No.", GetValue(XmlDoc, XmlNamespaces, '/resp:OrderResponse/cbc:SalesOrderID'), 'SalesOrderID must be the sales order number.');
        Assert.AreEqual(BuyerOrderNoTxt, GetValue(XmlDoc, XmlNamespaces, '/resp:OrderResponse/cac:OrderReference/cbc:ID'), 'OrderReference must be the buyer order number.');
        Assert.AreEqual(SellerEndpointId(), GetValue(XmlDoc, XmlNamespaces, '/resp:OrderResponse/cac:SellerSupplierParty/cac:Party/cbc:EndpointID'), 'Seller EndpointID');
        Assert.AreEqual(BuyerEndpointId(), GetValue(XmlDoc, XmlNamespaces, '/resp:OrderResponse/cac:BuyerCustomerParty/cac:Party/cbc:EndpointID'), 'Buyer EndpointID');
        Assert.AreEqual(0, CountNodes(XmlDoc, XmlNamespaces, '/resp:OrderResponse/cac:OrderLine'), 'An AP response must not contain lines.');
    end;

    [Test]
    procedure AcceptedOrderWithSellerChangesIsReportedAsConditionallyAccepted()
    var
        EDocument: Record "E-Document";
        EDocMessage: Record "E-Document Message";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        EDocMessageMgt: Codeunit "E-Doc. Message Mgt.";
        TempBlob: Codeunit "Temp Blob";
        XmlDoc: XmlDocument;
        XmlNamespaces: XmlNamespaceManager;
        BuiltResponseType: Enum "E-Doc. Response Type";
    begin
        // [SCENARIO] Quantity changes, zero quantities, removed lines and changed delivery dates are reported per line under CA.
        Initialize();

        // [GIVEN] An inbound order with four lines turned into a sales order
        CreateSalesOrderFromInboundOrder(EDocument, SalesHeader, 4);

        // [GIVEN] The seller promises another delivery date and price on line 1, changes line 2 quantity, sets line 3 to zero and deletes line 4
        FindSalesLine(SalesHeader, 1, SalesLine);
        SalesLine."Promised Delivery Date" := RequestedDeliveryDate() + 10;
        SalesLine."Unit Price" := 12;
        SalesLine.Modify();
        FindSalesLine(SalesHeader, 2, SalesLine);
        SalesLine.Validate(Quantity, 6);
        SalesLine.Modify(true);
        FindSalesLine(SalesHeader, 3, SalesLine);
        SalesLine.Validate(Quantity, 0);
        SalesLine.Modify(true);
        FindSalesLine(SalesHeader, 4, SalesLine);
        SalesLine.Delete(true);

        // [WHEN] The acceptance response is built
        BuiltResponseType := BuildResponse(EDocument, "E-Doc. Response Type"::Accepted, TempBlob);
        LoadResponse(TempBlob, XmlDoc, XmlNamespaces);

        // [THEN] The response is CA and every order line carries the seller's decision
        Assert.AreEqual('CA', GetValue(XmlDoc, XmlNamespaces, '/resp:OrderResponse/cbc:OrderResponseCode'), 'A changed order must be conditionally accepted.');
        Assert.AreEqual("E-Doc. Response Type"::"Conditionally Accepted", BuiltResponseType, 'The builder must report the acceptance as conditional.');
        Assert.AreEqual(4, CountNodes(XmlDoc, XmlNamespaces, '/resp:OrderResponse/cac:OrderLine'), 'Every order line must be answered.');
        Assert.AreEqual('3', GetLineValue(XmlDoc, XmlNamespaces, '1', 'cbc:LineStatusCode'), 'A changed delivery date must be reported as changed.');
        Assert.AreEqual(FormatXmlDate(RequestedDeliveryDate() + 10), GetLineValue(XmlDoc, XmlNamespaces, '1', 'cac:Delivery/cac:PromisedDeliveryPeriod/cbc:StartDate'), 'The promised delivery date must be reported.');
        Assert.AreEqual('3', GetLineValue(XmlDoc, XmlNamespaces, '2', 'cbc:LineStatusCode'), 'A changed quantity must be reported as changed.');
        Assert.AreEqual('6', GetLineValue(XmlDoc, XmlNamespaces, '2', 'cbc:Quantity'), 'The confirmed quantity must be reported.');
        Assert.AreEqual('EA', GetLineValue(XmlDoc, XmlNamespaces, '2', 'cbc:Quantity/@unitCode'), 'The quantity must use the ordered unit code.');
        Assert.AreEqual('0', GetLineValue(XmlDoc, XmlNamespaces, '2', 'cbc:MaximumBackorderQuantity'), 'A reduced line without backorder must state 0 remaining.');
        Assert.AreEqual('12', GetLineValue(XmlDoc, XmlNamespaces, '1', 'cac:Price/cbc:PriceAmount'), 'A changed price must be reported.');
        Assert.AreEqual('7', GetLineValue(XmlDoc, XmlNamespaces, '3', 'cbc:LineStatusCode'), 'A zero quantity line must be reported as not accepted.');
        Assert.AreEqual('7', GetLineValue(XmlDoc, XmlNamespaces, '4', 'cbc:LineStatusCode'), 'A removed line must be reported as not accepted.');
        Assert.AreEqual('Draft item 4', GetLineValue(XmlDoc, XmlNamespaces, '4', 'cac:Item/cbc:Name'), 'Every line, also a removed one, must name the ordered item.');

        // [THEN] Creating the response message stores it as Conditionally Accepted
        EDocMessage.Get(EDocMessageMgt.CreateResponseMessage(EDocument, "E-Document Message Type"::"PEPPOL Order Response", "E-Doc. Response Type"::Accepted));
        Assert.AreEqual("E-Doc. Response Type"::"Conditionally Accepted", EDocMessage."Response Type", 'The stored message must be Conditionally Accepted.');
        Assert.AreEqual("E-Document Direction"::Outgoing, EDocMessage.Direction, 'The response message must be outgoing.');
    end;

    [Test]
    procedure SellerAddedLinesAreReportedAsAdded()
    var
        EDocument: Record "E-Document";
        OtherItem: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempBlob: Codeunit "Temp Blob";
        XmlDoc: XmlDocument;
        XmlNamespaces: XmlNamespaceManager;
        BuiltResponseType: Enum "E-Doc. Response Type";
    begin
        // [SCENARIO] A sales line the seller adds for an ordered item is reported with status 1 as a split of that order line;
        // an added item that was not ordered has no order line to belong to and is left out.
        Initialize();

        // [GIVEN] A sales order created from an inbound order with two lines of the same item (10000: 5, 20000: 10)
        CreateSalesOrderFromInboundOrder(EDocument, SalesHeader);

        // [GIVEN] The seller confirms 6 of line 2 and adds a line for the other 4 of the same item below it
        FindSalesLine(SalesHeader, 2, SalesLine);
        SalesLine.Validate(Quantity, 6);
        SalesLine.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, SalesLine."No.", 4);

        // [GIVEN] The seller also inserts another item between line 1 and line 2
        LibraryEDoc.CreateItemWithStandardVAT(OtherItem);
        InsertSalesLine(SalesHeader, 15000, OtherItem."No.", 2);

        // [WHEN] The acceptance response is built
        BuiltResponseType := BuildResponse(EDocument, "E-Doc. Response Type"::Accepted, TempBlob);
        LoadResponse(TempBlob, XmlDoc, XmlNamespaces);

        // [THEN] The response is CA with both order lines and the split
        Assert.AreEqual('CA', GetValue(XmlDoc, XmlNamespaces, '/resp:OrderResponse/cbc:OrderResponseCode'), 'Added lines must make the response conditionally accepted.');
        Assert.AreEqual("E-Doc. Response Type"::"Conditionally Accepted", BuiltResponseType, 'The builder must report the acceptance as conditional.');
        Assert.AreEqual(3, CountNodes(XmlDoc, XmlNamespaces, '/resp:OrderResponse/cac:OrderLine'), 'Both order lines and the split must be answered.');

        // [THEN] The reduced line does not claim that nothing more will be delivered, as the added line delivers the rest
        Assert.AreEqual('3', GetLineValue(XmlDoc, XmlNamespaces, '2', 'cbc:LineStatusCode'), 'The reduced line must be reported as changed.');
        Assert.AreEqual('6', GetLineValue(XmlDoc, XmlNamespaces, '2', 'cbc:Quantity'), 'The reduced quantity must be reported.');
        Assert.AreEqual(0, CountNodes(XmlDoc, XmlNamespaces, '/resp:OrderResponse/cac:OrderLine/cac:LineItem[cbc:ID=''2'']/cbc:MaximumBackorderQuantity'), 'No backorder of 0 when an added line delivers the rest.');

        // [THEN] The added line of the same item is a split of order line 2
        Assert.AreEqual('1', GetLineValue(XmlDoc, XmlNamespaces, '30000', 'cbc:LineStatusCode'), 'An added line must have status 1.');
        Assert.AreEqual('4', GetLineValue(XmlDoc, XmlNamespaces, '30000', 'cbc:Quantity'), 'The added quantity must be reported.');
        Assert.AreEqual('EA', GetLineValue(XmlDoc, XmlNamespaces, '30000', 'cbc:Quantity/@unitCode'), 'An added line of the ordered item must use the ordered unit.');
        Assert.AreEqual('2', GetOrderLineReference(XmlDoc, XmlNamespaces, '30000'), 'A split must reference the order line of the same item.');

        // [THEN] The item that was not ordered is not attached to an unrelated order line
        Assert.AreEqual(0, CountNodes(XmlDoc, XmlNamespaces, '/resp:OrderResponse/cac:OrderLine/cac:LineItem[cbc:ID=''15000'']'), 'An added item that was not ordered must be left out.');
        Assert.AreEqual(0, CountNodes(XmlDoc, XmlNamespaces, StrSubstNo(ItemNameXPathTxt, OtherItem.Description)), 'No response line may carry the item that was not ordered.');
    end;

    [Test]
    procedure AddedItemThatWasNotOrderedIsLeftOut()
    var
        EDocument: Record "E-Document";
        OtherItem: Record Item;
        SalesHeader: Record "Sales Header";
        TempBlob: Codeunit "Temp Blob";
        XmlDoc: XmlDocument;
        XmlNamespaces: XmlNamespaceManager;
        BuiltResponseType: Enum "E-Doc. Response Type";
    begin
        // [SCENARIO] An extra item the buyer did not order does not turn an otherwise unchanged order into CA.
        Initialize();

        // [GIVEN] A sales order created from an inbound order, with an extra item the seller added below the order lines
        CreateSalesOrderFromInboundOrder(EDocument, SalesHeader);
        LibraryEDoc.CreateItemWithStandardVAT(OtherItem);
        InsertSalesLine(SalesHeader, 30000, OtherItem."No.", 2);

        // [WHEN] The acceptance response is built
        BuiltResponseType := BuildResponse(EDocument, "E-Doc. Response Type"::Accepted, TempBlob);
        LoadResponse(TempBlob, XmlDoc, XmlNamespaces);

        // [THEN] The order is accepted as ordered
        Assert.AreEqual('AP', GetValue(XmlDoc, XmlNamespaces, '/resp:OrderResponse/cbc:OrderResponseCode'), 'An unordered extra item must not change the response code.');
        Assert.AreEqual("E-Doc. Response Type"::Accepted, BuiltResponseType, 'The message must be stored as Accepted.');
        Assert.AreEqual(0, CountNodes(XmlDoc, XmlNamespaces, '/resp:OrderResponse/cac:OrderLine'), 'An AP response must not contain lines.');
    end;

    [Test]
    procedure PartialShipmentIsReportedAsBackorder()
    var
        EDocument: Record "E-Document";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempBlob: Codeunit "Temp Blob";
        XmlDoc: XmlDocument;
        XmlNamespaces: XmlNamespaceManager;
        BuiltResponseType: Enum "E-Doc. Response Type";
    begin
        // [SCENARIO] A seller keeping the ordered quantity but shipping only part of it now reports the rest as backorder.
        Initialize();

        // [GIVEN] A sales order with partial shipping created from an inbound order with two lines
        CreateSalesOrderFromInboundOrder(EDocument, SalesHeader);
        SalesHeader.Validate("Shipping Advice", SalesHeader."Shipping Advice"::Partial);
        SalesHeader.Modify(true);

        // [GIVEN] The seller ships 4 of the 10 ordered on line 2
        FindSalesLine(SalesHeader, 2, SalesLine);
        SalesLine.Validate("Qty. to Ship", 4);
        SalesLine.Modify(true);

        // [WHEN] The acceptance response is built
        BuiltResponseType := BuildResponse(EDocument, "E-Doc. Response Type"::Accepted, TempBlob);
        LoadResponse(TempBlob, XmlDoc, XmlNamespaces);

        // [THEN] Line 2 is changed, confirms 4 and backorders 6; line 1 is accepted with its quantity
        Assert.AreEqual('CA', GetValue(XmlDoc, XmlNamespaces, '/resp:OrderResponse/cbc:OrderResponseCode'), 'A backorder must be conditionally accepted.');
        Assert.AreEqual("E-Doc. Response Type"::"Conditionally Accepted", BuiltResponseType, 'The builder must report the acceptance as conditional.');
        Assert.AreEqual('3', GetLineValue(XmlDoc, XmlNamespaces, '2', 'cbc:LineStatusCode'), 'A backordered line must be reported as changed.');
        Assert.AreEqual('4', GetLineValue(XmlDoc, XmlNamespaces, '2', 'cbc:Quantity'), 'The quantity shipped now must be reported.');
        Assert.AreEqual('6', GetLineValue(XmlDoc, XmlNamespaces, '2', 'cbc:MaximumBackorderQuantity'), 'The remaining quantity must be reported as backorder.');
        Assert.AreEqual('EA', GetLineValue(XmlDoc, XmlNamespaces, '2', 'cbc:MaximumBackorderQuantity/@unitCode'), 'The backorder quantity must use the ordered unit code.');
        Assert.AreEqual('5', GetLineValue(XmlDoc, XmlNamespaces, '1', 'cbc:LineStatusCode'), 'An unchanged line must be reported as accepted.');
        Assert.AreEqual('5', GetLineValue(XmlDoc, XmlNamespaces, '1', 'cbc:Quantity'), 'An accepted line must report its quantity.');
        Assert.AreEqual(0, CountNodes(XmlDoc, XmlNamespaces, '/resp:OrderResponse/cac:OrderLine/cac:LineItem[cbc:ID=''1'']/cbc:MaximumBackorderQuantity'), 'A fully shipped line must not report a backorder.');
    end;

    [Test]
    procedure RescheduledShipmentIsReportedAsChanged()
    var
        EDocument: Record "E-Document";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempBlob: Codeunit "Temp Blob";
        NewPlannedDeliveryDate: Date;
        XmlDoc: XmlDocument;
        XmlNamespaces: XmlNamespaceManager;
        BuiltResponseType: Enum "E-Doc. Response Type";
    begin
        // [SCENARIO] A seller moving the shipment date reports the line as changed with the new planned delivery date.
        Initialize();

        // [GIVEN] A sales order created from an inbound order with two lines
        CreateSalesOrderFromInboundOrder(EDocument, SalesHeader);

        // [GIVEN] The seller moves the shipment of line 1 a week later
        FindSalesLine(SalesHeader, 1, SalesLine);
        NewPlannedDeliveryDate := SalesLine."Planned Delivery Date" + 7;
        SalesLine."Shipment Date" := SalesLine."Shipment Date" + 7;
        SalesLine."Planned Delivery Date" := NewPlannedDeliveryDate;
        SalesLine.Modify();

        // [WHEN] The acceptance response is built
        BuiltResponseType := BuildResponse(EDocument, "E-Doc. Response Type"::Accepted, TempBlob);
        LoadResponse(TempBlob, XmlDoc, XmlNamespaces);

        // [THEN] Line 1 is changed and carries the new planned delivery date; line 2 is accepted
        Assert.AreEqual('CA', GetValue(XmlDoc, XmlNamespaces, '/resp:OrderResponse/cbc:OrderResponseCode'), 'A rescheduled order must be conditionally accepted.');
        Assert.AreEqual("E-Doc. Response Type"::"Conditionally Accepted", BuiltResponseType, 'The builder must report the acceptance as conditional.');
        Assert.AreEqual('3', GetLineValue(XmlDoc, XmlNamespaces, '1', 'cbc:LineStatusCode'), 'A rescheduled line must be reported as changed.');
        Assert.AreEqual(FormatXmlDate(NewPlannedDeliveryDate), GetLineValue(XmlDoc, XmlNamespaces, '1', 'cac:Delivery/cac:PromisedDeliveryPeriod/cbc:StartDate'), 'The new planned delivery date must be reported.');
        Assert.AreEqual('5', GetLineValue(XmlDoc, XmlNamespaces, '2', 'cbc:LineStatusCode'), 'An unchanged line must be reported as accepted.');
    end;

    [Test]
    procedure AcknowledgementBeforeSalesOrderUsesBuyerOrderReference()
    var
        OriginalCompanyInformation: Record "Company Information";
        OriginalCustomer: Record Customer;
        EDocument: Record "E-Document";
        TempBlob: Codeunit "Temp Blob";
        XmlDoc: XmlDocument;
        XmlNamespaces: XmlNamespaceManager;
        BuiltResponseType: Enum "E-Doc. Response Type";
    begin
        // [SCENARIO] An acknowledgement sent before a sales order exists is AB, and without endpoints in the order both parties
        // are addressed by the Peppol identification BC uses for its own Peppol documents (here: GLN).
        Initialize();

        // [GIVEN] A company and a customer that use their GLN in electronic documents
        SetCompanyGLN(SellerEndpointId(), OriginalCompanyInformation);
        SetCustomerGLN(BuyerEndpointId(), OriginalCustomer);

        // [GIVEN] An inbound order draft without endpoint information
        CreateOrderDraftWithoutEndpoints(EDocument);

        // [WHEN] The acknowledgement is built
        BuiltResponseType := BuildResponse(EDocument, "E-Doc. Response Type"::Acknowledged, TempBlob);
        LoadResponse(TempBlob, XmlDoc, XmlNamespaces);

        // [THEN] AB refers to the buyer order
        Assert.AreEqual('AB', GetValue(XmlDoc, XmlNamespaces, '/resp:OrderResponse/cbc:OrderResponseCode'), 'OrderResponseCode');
        Assert.AreEqual("E-Doc. Response Type"::Acknowledged, BuiltResponseType, 'An acknowledgement must stay Acknowledged.');
        Assert.AreEqual(BuyerOrderNoTxt, GetValue(XmlDoc, XmlNamespaces, '/resp:OrderResponse/cac:OrderReference/cbc:ID'), 'OrderReference ID');

        // [THEN] Both parties are addressed by their GLN with the GLN scheme
        Assert.AreEqual(BuyerEndpointId(), GetValue(XmlDoc, XmlNamespaces, '/resp:OrderResponse/cac:BuyerCustomerParty/cac:Party/cbc:EndpointID'), 'Buyer EndpointID must fall back to the customer GLN.');
        Assert.AreEqual(GLNSchemeIdTxt, GetValue(XmlDoc, XmlNamespaces, '/resp:OrderResponse/cac:BuyerCustomerParty/cac:Party/cbc:EndpointID/@schemeID'), 'Buyer EndpointID schemeID');
        Assert.AreEqual(SellerEndpointId(), GetValue(XmlDoc, XmlNamespaces, '/resp:OrderResponse/cac:SellerSupplierParty/cac:Party/cbc:EndpointID'), 'Seller EndpointID must fall back to the company GLN.');
        Assert.AreEqual(GLNSchemeIdTxt, GetValue(XmlDoc, XmlNamespaces, '/resp:OrderResponse/cac:SellerSupplierParty/cac:Party/cbc:EndpointID/@schemeID'), 'Seller EndpointID schemeID');

        RestoreCustomer(OriginalCustomer);
        RestoreCompanyInformation(OriginalCompanyInformation);
    end;

    [Test]
    procedure ResponseWithoutEndpointSchemeIsNotCreated()
    var
        CountryRegion: Record "Country/Region";
        OriginalCompanyInformation: Record "Company Information";
        OriginalCustomer: Record Customer;
        EDocument: Record "E-Document";
        TempBlob: Codeunit "Temp Blob";
    begin
        // [SCENARIO] A customer addressed by VAT registration no. in a country without VAT Scheme would give an EndpointID
        // without the mandatory schemeID, so the response is not built.
        Initialize();

        // [GIVEN] A company with a GLN, and a customer with only a VAT registration no. in a country without VAT Scheme
        SetCompanyGLN(SellerEndpointId(), OriginalCompanyInformation);
        SetCustomerGLN('', OriginalCustomer);
        LibraryERM.CreateCountryRegion(CountryRegion);
        Customer.Get(Customer."No.");
        Customer."Country/Region Code" := CountryRegion.Code;
        Customer."VAT Registration No." := 'X12345678';
        Customer.Modify();

        // [GIVEN] An inbound order draft without endpoint information
        CreateOrderDraftWithoutEndpoints(EDocument);

        // [WHEN] The acknowledgement is built
        asserterror BuildResponse(EDocument, "E-Doc. Response Type"::Acknowledged, TempBlob);

        // [THEN] The error points to the missing VAT Scheme
        Assert.ExpectedError(CountryRegion.FieldCaption("VAT Scheme"));

        RestoreCustomer(OriginalCustomer);
        RestoreCompanyInformation(OriginalCompanyInformation);
    end;

    [Test]
    procedure ResponseWithoutAnySellerEndpointIsNotCreated()
    var
        CompanyInformation: Record "Company Information";
        OriginalCompanyInformation: Record "Company Information";
        EDocument: Record "E-Document";
        TempBlob: Codeunit "Temp Blob";
    begin
        // [SCENARIO] Without an endpoint in the order and without GLN or VAT registration no. on the company,
        // the response would miss the mandatory cbc:EndpointID, so it is not built.
        Initialize();

        // [GIVEN] An inbound order draft without endpoint information and a company without Peppol identification
        CreateOrderDraftWithoutEndpoints(EDocument);
        CompanyInformation.Get();
        OriginalCompanyInformation := CompanyInformation;
        CompanyInformation.GLN := '';
        CompanyInformation."Use GLN in Electronic Document" := false;
        CompanyInformation."VAT Registration No." := '';
        CompanyInformation.Modify();

        // [WHEN] The acknowledgement is built
        asserterror BuildResponse(EDocument, "E-Doc. Response Type"::Acknowledged, TempBlob);

        // [THEN] The standard Peppol error names the missing company identification
        Assert.ExpectedError(CompanyInformation.FieldCaption("VAT Registration No."));

        RestoreCompanyInformation(OriginalCompanyInformation);
    end;

    local procedure CreateSalesOrderFromInboundOrder(var EDocument: Record "E-Document"; var SalesHeader: Record "Sales Header")
    begin
        CreateSalesOrderFromInboundOrder(EDocument, SalesHeader, 2);
    end;

    local procedure CreateSalesOrderFromInboundOrder(var EDocument: Record "E-Document"; var SalesHeader: Record "Sales Header"; NoOfLines: Integer)
    var
        EDocSalesHeader: Record "E-Document Sales Header";
        EDocSalesLine: Record "E-Document Sales Line";
        Item: Record Item;
        EDocSalesDocHelper: Codeunit "E-Doc. Sales Doc. Helper";
        i: Integer;
    begin
        LibraryEDoc.CreateInboundEDocument(EDocument, EDocumentService);
        EDocSalesHeader.InsertForEDocument(EDocument);
        EDocSalesHeader."Buyer Order No." := BuyerOrderNoTxt;
        EDocSalesHeader."Buyer Company Name" := 'Buyer Inc.';
        EDocSalesHeader."Buyer Endpoint Id" := BuyerEndpointId();
        EDocSalesHeader."Buyer Endpoint Scheme Id" := GLNSchemeIdTxt;
        EDocSalesHeader."Seller Endpoint Id" := SellerEndpointId();
        EDocSalesHeader."Seller Endpoint Scheme Id" := GLNSchemeIdTxt;
        EDocSalesHeader."[BC] Customer No." := Customer."No.";
        EDocSalesHeader.Modify();

        LibrarySales.CreateSalesHeader(SalesHeader, "Sales Document Type"::Order, Customer."No.");
        LibraryEDoc.CreateItemWithStandardVAT(Item);
        for i := 1 to NoOfLines do begin
            Clear(EDocSalesLine);
            EDocSalesLine."E-Document Entry No." := EDocument."Entry No";
            EDocSalesLine."Line No." := i * 10000;
            EDocSalesLine."External Line Id" := Format(i);
            EDocSalesLine.Description := CopyStr('Draft item ' + Format(i), 1, MaxStrLen(EDocSalesLine.Description));
            EDocSalesLine.Quantity := 5 * i;
            EDocSalesLine."Unit of Measure" := 'EA';
            EDocSalesLine."Unit Price" := 10;
            EDocSalesLine."Requested Delivery Date" := RequestedDeliveryDate();
            EDocSalesLine."[BC] Sales Line Type" := "Sales Line Type"::Item;
            EDocSalesLine."[BC] Sales Line No." := Item."No.";
            EDocSalesLine."[BC] Unit of Measure" := Item."Base Unit of Measure";
            EDocSalesLine.Insert();
            // Same path as finishing a sales order draft: creates the sales line, the link and the date snapshot
            EDocSalesDocHelper.CreateSalesLineFromDraft(SalesHeader, EDocSalesLine, false, i * 10000);
        end;

        EDocument."Document Record ID" := SalesHeader.RecordId();
        EDocument.Modify();
    end;

    local procedure FindSalesLine(SalesHeader: Record "Sales Header"; LineIndex: Integer; var SalesLine: Record "Sales Line")
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindSet();
        SalesLine.Next(LineIndex - 1);
    end;

    local procedure BuildResponse(EDocument: Record "E-Document"; ResponseType: Enum "E-Doc. Response Type"; var TempBlob: Codeunit "Temp Blob"): Enum "E-Doc. Response Type"
    var
        EDocPEPPOLMsgBuilder: Codeunit "E-Doc. PEPPOL Msg. Builder";
    begin
        exit(EDocPEPPOLMsgBuilder.BuildResponseMessage(EDocument, ResponseType, TempBlob));
    end;

    local procedure RequestedDeliveryDate(): Date
    begin
        exit(WorkDate() + 30);
    end;

    local procedure FormatXmlDate(Value: Date): Text
    begin
        exit(Format(Value, 0, 9));
    end;

    local procedure BuyerEndpointId(): Text[13]
    begin
        exit('1234567890128');
    end;

    local procedure SellerEndpointId(): Text[13]
    begin
        exit('9876543210987');
    end;

    local procedure LoadResponse(var TempBlob: Codeunit "Temp Blob"; var XmlDoc: XmlDocument; var XmlNamespaces: XmlNamespaceManager)
    var
        InStr: InStream;
    begin
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        XmlDocument.ReadFrom(InStr, XmlDoc);
        XmlNamespaces.NameTable(XmlDoc.NameTable());
        XmlNamespaces.AddNamespace('resp', 'urn:oasis:names:specification:ubl:schema:xsd:OrderResponse-2');
        XmlNamespaces.AddNamespace('cac', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
        XmlNamespaces.AddNamespace('cbc', 'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2');
    end;

    local procedure CreateOrderDraftWithoutEndpoints(var EDocument: Record "E-Document")
    var
        EDocSalesHeader: Record "E-Document Sales Header";
    begin
        LibraryEDoc.CreateInboundEDocument(EDocument, EDocumentService);
        EDocSalesHeader.InsertForEDocument(EDocument);
        EDocSalesHeader."Buyer Order No." := BuyerOrderNoTxt;
        EDocSalesHeader."[BC] Customer No." := Customer."No.";
        EDocSalesHeader.Modify();
    end;

    local procedure SetCompanyGLN(NewGLN: Code[13]; var OriginalCompanyInformation: Record "Company Information")
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        OriginalCompanyInformation := CompanyInformation;
        CompanyInformation.GLN := NewGLN;
        CompanyInformation."Use GLN in Electronic Document" := NewGLN <> '';
        CompanyInformation.Modify();
    end;

    local procedure SetCustomerGLN(NewGLN: Code[13]; var OriginalCustomer: Record Customer)
    begin
        Customer.Get(Customer."No.");
        OriginalCustomer := Customer;
        Customer.GLN := NewGLN;
        Customer."Use GLN in Electronic Document" := NewGLN <> '';
        Customer.Modify();
    end;

    local procedure RestoreCompanyInformation(OriginalCompanyInformation: Record "Company Information")
    var
        CompanyInformation: Record "Company Information";
    begin
        // Re-read before modifying: the saved copy predates the test's own Modify and would fail the concurrency check
        CompanyInformation.Get();
        CompanyInformation.GLN := OriginalCompanyInformation.GLN;
        CompanyInformation."Use GLN in Electronic Document" := OriginalCompanyInformation."Use GLN in Electronic Document";
        CompanyInformation."VAT Registration No." := OriginalCompanyInformation."VAT Registration No.";
        CompanyInformation.Modify();
    end;

    local procedure RestoreCustomer(OriginalCustomer: Record Customer)
    begin
        Customer.Get(OriginalCustomer."No.");
        Customer.GLN := OriginalCustomer.GLN;
        Customer."Use GLN in Electronic Document" := OriginalCustomer."Use GLN in Electronic Document";
        Customer."Country/Region Code" := OriginalCustomer."Country/Region Code";
        Customer."VAT Registration No." := OriginalCustomer."VAT Registration No.";
        Customer.Modify();
    end;

    local procedure InsertSalesLine(SalesHeader: Record "Sales Header"; LineNo: Integer; ItemNo: Code[20]; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine."Line No." := LineNo;
        SalesLine.Insert(true);
        SalesLine.Validate(Type, SalesLine.Type::Item);
        SalesLine.Validate("No.", ItemNo);
        SalesLine.Validate(Quantity, Quantity);
        SalesLine.Modify(true);
    end;

    local procedure GetOrderLineReference(XmlDoc: XmlDocument; XmlNamespaces: XmlNamespaceManager; ResponseLineId: Text): Text
    begin
        exit(GetValue(XmlDoc, XmlNamespaces, StrSubstNo(OrderLineReferenceXPathTxt, ResponseLineId)));
    end;

    local procedure GetLineValue(XmlDoc: XmlDocument; XmlNamespaces: XmlNamespaceManager; LineId: Text; RelativePath: Text): Text
    begin
        exit(GetValue(XmlDoc, XmlNamespaces, StrSubstNo(LineXPathTxt, LineId, RelativePath)));
    end;

    local procedure GetValue(XmlDoc: XmlDocument; XmlNamespaces: XmlNamespaceManager; XPath: Text): Text
    var
        Node: XmlNode;
    begin
        Assert.IsTrue(XmlDoc.SelectSingleNode(XPath, XmlNamespaces, Node), StrSubstNo(NodeMustExistErr, XPath));
        if Node.IsXmlAttribute() then
            exit(Node.AsXmlAttribute().Value());
        exit(Node.AsXmlElement().InnerText());
    end;

    local procedure CountNodes(XmlDoc: XmlDocument; XmlNamespaces: XmlNamespaceManager; XPath: Text): Integer
    var
        Nodes: XmlNodeList;
    begin
        XmlDoc.SelectNodes(XPath, XmlNamespaces, Nodes);
        exit(Nodes.Count());
    end;

    local procedure Initialize()
    var
        EDocDataStorage: Record "E-Doc. Data Storage";
        EDocRecordLink: Record "E-Doc. Record Link";
        EDocument: Record "E-Document";
        EDocMessage: Record "E-Document Message";
        EDocSalesHeader: Record "E-Document Sales Header";
        EDocSalesLine: Record "E-Document Sales Line";
        EDocumentServiceStatus: Record "E-Document Service Status";
    begin
        LibraryLowerPermission.SetOutsideO365Scope();

        EDocMessage.DeleteAll();
        EDocumentServiceStatus.DeleteAll();
        EDocument.DeleteAll();
        EDocDataStorage.DeleteAll();
        // E-Document entry numbers restart after the delete above, so drafts left by earlier tests would collide
        EDocSalesHeader.DeleteAll();
        EDocSalesLine.DeleteAll();
        EDocRecordLink.DeleteAll();

        if IsInitialized then
            exit;

        LibraryEDoc.SetupStandardVAT();
        EDocumentService.DeleteAll();
        LibraryEDoc.SetupStandardSalesScenario(Customer, EDocumentService, Enum::"E-Document Format"::Mock, Enum::"Service Integration"::"Mock");

        IsInitialized := true;
    end;
}
