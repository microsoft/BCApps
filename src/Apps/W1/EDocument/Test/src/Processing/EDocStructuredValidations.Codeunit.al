// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Test;

using Microsoft.eServices.EDocument.Processing.Import.Purchase;
using Microsoft.Finance.GeneralLedger.Setup;

codeunit 139894 "EDoc Structured Validations"
{

    var
        Assert: Codeunit Assert;

    #region CAPI
    internal procedure AssertFullCAPIDocumentExtracted(EDocumentEntryNo: Integer)
    var
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
    begin
        EDocumentPurchaseHeader.Get(EDocumentEntryNo);

        Assert.AreEqual('MICROSOFT CORPORATION', EDocumentPurchaseHeader."Customer Company Name", 'The customer company name does not allign with the mock data.');
        Assert.AreEqual('CID-12345', EDocumentPurchaseHeader."Customer Company Id", 'The customer company id does not allign with the mock data.');
        Assert.AreEqual('PO-3333', EDocumentPurchaseHeader."Purchase Order No.", 'The purchase order number does not allign with the mock data.');
        Assert.AreEqual('INV-100', EDocumentPurchaseHeader."Sales Invoice No.", 'The sales invoice number does not allign with the mock data.');
        Assert.AreEqual(DMY2Date(15, 12, 2019), EDocumentPurchaseHeader."Due Date", 'The due date does not allign with the mock data.');
        Assert.AreEqual('CONTOSO LTD.', EDocumentPurchaseHeader."Vendor Company Name", 'The vendor name does not allign with the mock data.');
        Assert.AreEqual('123 456th St New York, NY, 10001', EDocumentPurchaseHeader."Vendor Address", 'The vendor address does not allign with the mock data.');
        Assert.AreEqual('Contoso Headquarters', EDocumentPurchaseHeader."Vendor Address Recipient", 'The vendor address recipient does not allign with the mock data.');
        Assert.AreEqual('123 Other St, Redmond WA, 98052', EDocumentPurchaseHeader."Customer Address", 'The customer address does not allign with the mock data.');
        Assert.AreEqual('Microsoft Corp', EDocumentPurchaseHeader."Customer Address Recipient", 'The customer address recipient does not allign with the mock data.');
        Assert.AreEqual('123 Bill St, Redmond WA, 98052', EDocumentPurchaseHeader."Billing Address", 'The billing address does not allign with the mock data.');
        Assert.AreEqual('Microsoft Finance', EDocumentPurchaseHeader."Billing Address Recipient", 'The billing address recipient does not allign with the mock data.');
        Assert.AreEqual('123 Ship St, Redmond WA, 98052', EDocumentPurchaseHeader."Shipping Address", 'The shipping address does not allign with the mock data.');
        Assert.AreEqual('Microsoft Delivery', EDocumentPurchaseHeader."Shipping Address Recipient", 'The shipping address recipient does not allign with the mock data.');
        Assert.AreEqual(100, EDocumentPurchaseHeader."Sub Total", 'The sub total does not allign with the mock data.');
        Assert.AreEqual(10, EDocumentPurchaseHeader."Total VAT", 'The total tax does not allign with the mock data.');
        Assert.AreEqual(110, EDocumentPurchaseHeader.Total, 'The total does not allign with the mock data.');
        Assert.AreEqual(610, EDocumentPurchaseHeader."Amount Due", 'The amount due does not allign with the mock data.');
        Assert.AreEqual(500, EDocumentPurchaseHeader."Previous Unpaid Balance", 'The previous unpaid balance does not allign with the mock data.');
        Assert.AreEqual('XYZ', EDocumentPurchaseHeader."Currency Code", 'The currency code does not allign with the mock data.');
        Assert.AreEqual('123 Remit St New York, NY, 10001', EDocumentPurchaseHeader."Remittance Address", 'The remittance address does not allign with the mock data.');
        Assert.AreEqual('Contoso Billing', EDocumentPurchaseHeader."Remittance Address Recipient", 'The remittance address recipient does not allign with the mock data.');
        Assert.AreEqual(DMY2Date(14, 10, 2019), EDocumentPurchaseHeader."Service Start Date", 'The service start date does not allign with the mock data.');
        Assert.AreEqual(DMY2Date(14, 11, 2019), EDocumentPurchaseHeader."Service End Date", 'The service end date does not allign with the mock data.');

        EDocumentPurchaseLine.SetRange("E-Document Entry No.", EDocumentEntryNo);
        EDocumentPurchaseLine.FindSet();
        Assert.AreEqual(60, EDocumentPurchaseLine."Sub Total", 'The amount in the purchase line does not allign with the mock data.');
        Assert.AreEqual('Consulting Services', EDocumentPurchaseLine.Description, 'The description in the purchase line does not allign with the mock data.');
        Assert.AreEqual(30, EDocumentPurchaseLine."Unit Price", 'The unit price in the purchase line does not allign with the mock data.');
        Assert.AreEqual(2, EDocumentPurchaseLine.Quantity, 'The quantity in the purchase line does not allign with the mock data.');
        Assert.AreEqual('XYZ', EDocumentPurchaseLine."Currency Code", 'The currency code in the purchase line does not allign with the mock data.');
        Assert.AreEqual('A123', EDocumentPurchaseLine."Product Code", 'The product code in the purchase line does not allign with the mock data.');
        Assert.AreEqual('hours', EDocumentPurchaseLine."Unit of Measure", 'The unit of measure in the purchase line does not allign with the mock data.');
        Assert.AreEqual(DMY2Date(4, 3, 2021), EDocumentPurchaseLine.Date, 'The date in the purchase line does not allign with the mock data.');
        Assert.AreEqual(6, EDocumentPurchaseLine."VAT Rate", 'The amount in the purchase line does not allign with the mock data.');

        EDocumentPurchaseLine.Next();
        Assert.AreEqual(30, EDocumentPurchaseLine."Sub Total", 'The amount in the purchase line does not allign with the mock data.');
        Assert.AreEqual('Document Fee', EDocumentPurchaseLine.Description, 'The description in the purchase line does not allign with the mock data.');
        Assert.AreEqual(10, EDocumentPurchaseLine."Unit Price", 'The unit price in the purchase line does not allign with the mock data.');
        Assert.AreEqual(3, EDocumentPurchaseLine.Quantity, 'The quantity in the purchase line does not allign with the mock data.');
        Assert.AreEqual('XYZ', EDocumentPurchaseLine."Currency Code", 'The currency code in the purchase line does not allign with the mock data.');
        Assert.AreEqual('B456', EDocumentPurchaseLine."Product Code", 'The product code in the purchase line does not allign with the mock data.');
        Assert.AreEqual('', EDocumentPurchaseLine."Unit of Measure", 'The unit of measure in the purchase line does not allign with the mock data.');
        Assert.AreEqual(DMY2Date(5, 3, 2021), EDocumentPurchaseLine.Date, 'The date in the purchase line does not allign with the mock data.');
        Assert.AreEqual(3, EDocumentPurchaseLine."VAT Rate", 'The amount in the purchase line does not allign with the mock data.');

        EDocumentPurchaseLine.Next();
        Assert.AreEqual(10, EDocumentPurchaseLine."Sub Total", 'The amount does not allign with the mock data.');
        Assert.AreEqual('Printing Fee', EDocumentPurchaseLine.Description, 'The description does not allign with the mock data.');
        Assert.AreEqual(1, EDocumentPurchaseLine."Unit Price", 'The unit price does not allign with the mock data.');
        Assert.AreEqual(10, EDocumentPurchaseLine.Quantity, 'The quantity does not allign with the mock data.');
        Assert.AreEqual('C789', EDocumentPurchaseLine."Product Code", 'The product code does not allign with the mock data.');
        Assert.AreEqual('pages', EDocumentPurchaseLine."Unit of Measure", 'The unit of measure does not allign with the mock data.');
        Assert.AreEqual(DMY2Date(6, 3, 2021), EDocumentPurchaseLine.Date, 'The date does not allign with the mock data.');
        Assert.AreEqual(1, EDocumentPurchaseLine."VAT Rate", 'The amount does not allign with the mock data.');
    end;

    internal procedure AssertMinimalCAPIDocumentParsed(EDocumentEntryNo: Integer)
    var
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
    begin
        EDocumentPurchaseHeader.Get(EDocumentEntryNo);

        Assert.AreEqual('INV-100', EDocumentPurchaseHeader."Sales Invoice No.", 'The sales invoice number does not allign with the mock data.');
        Assert.AreEqual(DMY2Date(15, 12, 2019), EDocumentPurchaseHeader."Due Date", 'The due date does not allign with the mock data.');
        Assert.AreEqual('CONTOSO LTD.', EDocumentPurchaseHeader."Vendor Company Name", 'The vendor name does not allign with the mock data.');
        Assert.AreEqual(110, EDocumentPurchaseHeader.Total, 'The total does not allign with the mock data.');
        Assert.AreEqual('XYZ', EDocumentPurchaseHeader."Currency Code", 'The currency code does not allign with the mock data.');

        EDocumentPurchaseLine.SetRange("E-Document Entry No.", EDocumentEntryNo);
        EDocumentPurchaseLine.FindSet();
        Assert.AreEqual(60, EDocumentPurchaseLine."Sub Total", 'The amount in the purchase line does not allign with the mock data.');
        Assert.AreEqual('Consulting Services', EDocumentPurchaseLine.Description, 'The description in the purchase line does not allign with the mock data.');

        EDocumentPurchaseLine.Next();
        Assert.AreEqual(30, EDocumentPurchaseLine."Sub Total", 'The amount in the purchase line does not allign with the mock data.');
        Assert.AreEqual('Document Fee', EDocumentPurchaseLine.Description, 'The description in the purchase line does not allign with the mock data.');

        EDocumentPurchaseLine.Next();
        Assert.AreEqual(10, EDocumentPurchaseLine."Sub Total", 'The amount does not allign with the mock data.');
        Assert.AreEqual('Printing Fee', EDocumentPurchaseLine.Description, 'The description does not allign with the mock data.');
    end;
    #endregion

    #region PEPPOL
    internal procedure AssertFullPEPPOLDocumentExtracted(EDocumentEntryNo: Integer)
    var
        GLSetup: Record "General Ledger Setup";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
    begin
        GLSetup.Get();
        EDocumentPurchaseHeader.Get(EDocumentEntryNo);
        Assert.AreEqual('103033', EDocumentPurchaseHeader."Sales Invoice No.", 'The sales invoice number does not allign with the mock data.');
        Assert.AreEqual(DMY2Date(22, 01, 2026), EDocumentPurchaseHeader."Document Date", 'The invoice date does not allign with the mock data.');
        Assert.AreEqual(DMY2Date(22, 02, 2026), EDocumentPurchaseHeader."Due Date", 'The due date does not allign with the mock data.');
        Assert.AreEqual('XYZ', EDocumentPurchaseHeader."Currency Code", 'The currency code does not allign with the mock data.');
        Assert.AreEqual('2', EDocumentPurchaseHeader."Purchase Order No.", 'The purchase order number does not allign with the mock data.');
        Assert.AreEqual('CRONUS International', EDocumentPurchaseHeader."Vendor Company Name", 'The vendor name does not allign with the mock data.');
        Assert.AreEqual('Main Street, 14', EDocumentPurchaseHeader."Vendor Address", 'The vendor street does not allign with the mock data.');
        Assert.AreEqual('GB123456789', EDocumentPurchaseHeader."Vendor VAT Id", 'The vendor VAT id does not allign with the mock data.');
        Assert.AreEqual('Jim Olive', EDocumentPurchaseHeader."Vendor Contact Name", 'The vendor contact name does not allign with the mock data.');
        Assert.AreEqual('The Cannon Group PLC', EDocumentPurchaseHeader."Customer Company Name", 'The customer name does not allign with the mock data.');
        Assert.AreEqual('GB789456278', EDocumentPurchaseHeader."Customer VAT Id", 'The customer VAT id does not allign with the mock data.');
        Assert.AreEqual('192 Market Square', EDocumentPurchaseHeader."Customer Address", 'The customer address does not allign with the mock data.');

        EDocumentPurchaseLine.SetRange("E-Document Entry No.", EDocumentEntryNo);
        EDocumentPurchaseLine.FindSet();
        Assert.AreEqual(1, EDocumentPurchaseLine."Quantity", 'The quantity in the purchase line does not allign with the mock data.');
        Assert.AreEqual('PCS', EDocumentPurchaseLine."Unit of Measure", 'The unit of measure in the purchase line does not allign with the mock data.');
        Assert.AreEqual(4000, EDocumentPurchaseLine."Sub Total", 'The total amount before taxes in the purchase line does not allign with the mock data.');
        Assert.AreEqual('XYZ', EDocumentPurchaseLine."Currency Code", 'The currency code in the purchase line does not allign with the mock data.');
        Assert.AreEqual(0, EDocumentPurchaseLine."Total Discount", 'The total discount in the purchase line does not allign with the mock data.');
        Assert.AreEqual('Bicycle', EDocumentPurchaseLine.Description, 'The product description in the purchase line does not allign with the mock data.');
        Assert.AreEqual('1000', EDocumentPurchaseLine."Product Code", 'The product code in the purchase line does not allign with the mock data.');
        Assert.AreEqual(25, EDocumentPurchaseLine."VAT Rate", 'The VAT rate in the purchase line does not allign with the mock data.');
        Assert.AreEqual(4000, EDocumentPurchaseLine."Unit Price", 'The unit price in the purchase line does not allign with the mock data.');

        EDocumentPurchaseLine.Next();
        Assert.AreEqual(2, EDocumentPurchaseLine."Quantity", 'The quantity in the purchase line does not allign with the mock data.');
        Assert.AreEqual('PCS', EDocumentPurchaseLine."Unit of Measure", 'The unit of measure in the purchase line does not allign with the mock data.');
        Assert.AreEqual(10000, EDocumentPurchaseLine."Sub Total", 'The total amount before taxes in the purchase line does not allign with the mock data.');
        Assert.AreEqual('XYZ', EDocumentPurchaseLine."Currency Code", 'The currency code in the purchase line does not allign with the mock data.');
        Assert.AreEqual(0, EDocumentPurchaseLine."Total Discount", 'The total discount in the purchase line does not allign with the mock data.');
        Assert.AreEqual('Bicycle v2', EDocumentPurchaseLine.Description, 'The product description in the purchase line does not allign with the mock data.');
        Assert.AreEqual('2000', EDocumentPurchaseLine."Product Code", 'The product code in the purchase line does not allign with the mock data.');
        Assert.AreEqual(25, EDocumentPurchaseLine."VAT Rate", 'The VAT rate in the purchase line does not allign with the mock data.');
        Assert.AreEqual(5000, EDocumentPurchaseLine."Unit Price", 'The unit price in the purchase line does not allign with the mock data.');

    end;
    internal procedure AssertFullPEPPOLCreditNoteExtracted(EDocumentEntryNo: Integer)
    var
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
    begin
        EDocumentPurchaseHeader.Get(EDocumentEntryNo);
        Assert.AreEqual('CN-5001', EDocumentPurchaseHeader."Sales Invoice No.", 'The credit note number does not match the mock data.');
        Assert.AreEqual(DMY2Date(15, 02, 2026), EDocumentPurchaseHeader."Document Date", 'The document date does not match the mock data.');
        Assert.AreEqual(DMY2Date(15, 03, 2026), EDocumentPurchaseHeader."Due Date", 'The due date does not match the mock data.');
        Assert.AreEqual('XYZ', EDocumentPurchaseHeader."Currency Code", 'The currency code does not match the mock data.');
        Assert.AreEqual('5', EDocumentPurchaseHeader."Purchase Order No.", 'The order reference does not match the mock data.');
        Assert.AreEqual('103033', EDocumentPurchaseHeader."Vendor Invoice No.", 'The billing reference (vendor invoice no.) does not match the mock data.');
        Assert.AreEqual('CRONUS International', EDocumentPurchaseHeader."Vendor Company Name", 'The vendor name does not match the mock data.');
        Assert.AreEqual('Main Street, 14', EDocumentPurchaseHeader."Vendor Address", 'The vendor street does not match the mock data.');
        Assert.AreEqual('GB123456789', EDocumentPurchaseHeader."Vendor VAT Id", 'The vendor VAT id does not match the mock data.');
        Assert.AreEqual('Jim Olive', EDocumentPurchaseHeader."Vendor Contact Name", 'The vendor contact name does not match the mock data.');
        Assert.AreEqual('The Cannon Group PLC', EDocumentPurchaseHeader."Customer Company Name", 'The customer name does not match the mock data.');
        Assert.AreEqual('GB789456278', EDocumentPurchaseHeader."Customer VAT Id", 'The customer VAT id does not match the mock data.');
        Assert.AreEqual('192 Market Square', EDocumentPurchaseHeader."Customer Address", 'The customer address does not match the mock data.');
        Assert.AreEqual(2500, EDocumentPurchaseHeader.Total, 'The total does not match the mock data.');
        Assert.AreEqual(2000, EDocumentPurchaseHeader."Sub Total", 'The sub total does not match the mock data.');
        Assert.AreEqual(0, EDocumentPurchaseHeader."Total Discount", 'The total discount does not match the mock data.');
        Assert.AreEqual(500, EDocumentPurchaseHeader."Total VAT", 'The total VAT does not match the mock data.');

        EDocumentPurchaseLine.SetRange("E-Document Entry No.", EDocumentEntryNo);
        EDocumentPurchaseLine.FindFirst();
        Assert.AreEqual(1, EDocumentPurchaseLine."Quantity", 'The quantity in the credit note line does not match the mock data.');
        Assert.AreEqual('PCS', EDocumentPurchaseLine."Unit of Measure", 'The unit of measure in the credit note line does not match the mock data.');
        Assert.AreEqual(2000, EDocumentPurchaseLine."Sub Total", 'The line extension amount does not match the mock data.');
        Assert.AreEqual('XYZ', EDocumentPurchaseLine."Currency Code", 'The currency code in the credit note line does not match the mock data.');
        Assert.AreEqual('Bicycle - Return', EDocumentPurchaseLine.Description, 'The description in the credit note line does not match the mock data.');
        Assert.AreEqual('1000', EDocumentPurchaseLine."Product Code", 'The product code in the credit note line does not match the mock data.');
        Assert.AreEqual(25, EDocumentPurchaseLine."VAT Rate", 'The VAT rate in the credit note line does not match the mock data.');
        Assert.AreEqual(2000, EDocumentPurchaseLine."Unit Price", 'The unit price in the credit note line does not match the mock data.');
    end;

    internal procedure AssertPEPPOLBaseExampleExtracted(EDocumentEntryNo: Integer)
    var
        GLSetup: Record "General Ledger Setup";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
    begin
        GLSetup.Get();
        EDocumentPurchaseHeader.Get(EDocumentEntryNo);
        Assert.AreEqual('Snippet1', EDocumentPurchaseHeader."Sales Invoice No.", 'The invoice ID does not match.');
        Assert.AreEqual(DMY2Date(13, 11, 2017), EDocumentPurchaseHeader."Document Date", 'The document date does not match.');
        Assert.AreEqual(DMY2Date(01, 12, 2017), EDocumentPurchaseHeader."Due Date", 'The due date does not match.');
        Assert.AreEqual(ExpectedCurrencyCode('EUR', GLSetup."LCY Code"), EDocumentPurchaseHeader."Currency Code", 'The currency code does not match.');
        Assert.AreEqual('SupplierTradingName Ltd.', EDocumentPurchaseHeader."Vendor Company Name", 'The vendor name does not match.');
        Assert.AreEqual('Main street 1', EDocumentPurchaseHeader."Vendor Address", 'The vendor address does not match.');
        Assert.AreEqual('GB1232434', EDocumentPurchaseHeader."Vendor VAT Id", 'The vendor VAT id does not match.');
        Assert.AreEqual('9482348239847', EDocumentPurchaseHeader."Vendor GLN", 'The vendor GLN should be populated for schemeID=0088.');
        Assert.AreEqual('BuyerTradingName AS', EDocumentPurchaseHeader."Customer Company Name", 'The customer name does not match.');
        Assert.AreEqual('SE4598375937', EDocumentPurchaseHeader."Customer VAT Id", 'The customer VAT id does not match.');
        Assert.AreEqual('Hovedgatan 32', EDocumentPurchaseHeader."Customer Address", 'The customer address does not match.');
        Assert.AreEqual('', EDocumentPurchaseHeader."Customer GLN", 'Customer GLN should be empty for schemeID=0002.');
        Assert.AreEqual('0002:FR23342', EDocumentPurchaseHeader."Customer Company Id", 'Customer Company Id should be schemeID:value.');
        Assert.AreEqual(1656.25, EDocumentPurchaseHeader.Total, 'The total does not match.');
        Assert.AreEqual(1325, EDocumentPurchaseHeader."Sub Total", 'The sub total does not match.');

        EDocumentPurchaseLine.SetRange("E-Document Entry No.", EDocumentEntryNo);
        Assert.AreEqual(3, EDocumentPurchaseLine.Count(), 'Expected 2 invoice lines + 1 charge line = 3 lines.');

        EDocumentPurchaseLine.FindSet();
        // Line 1: 7 x 400 EUR
        Assert.AreEqual(7, EDocumentPurchaseLine.Quantity, 'Line 1 quantity does not match.');
        Assert.AreEqual('DAY', EDocumentPurchaseLine."Unit of Measure", 'Line 1 unit of measure does not match.');
        Assert.AreEqual(2800, EDocumentPurchaseLine."Sub Total", 'Line 1 sub total does not match.');
        Assert.AreEqual('item name', EDocumentPurchaseLine.Description, 'Line 1 description does not match.');
        Assert.AreEqual('21382183120983', EDocumentPurchaseLine."Product Code", 'Line 1 product code should be StandardItemIdentification.');
        Assert.AreEqual(25, EDocumentPurchaseLine."VAT Rate", 'Line 1 VAT rate does not match.');
        Assert.AreEqual(400, EDocumentPurchaseLine."Unit Price", 'Line 1 unit price does not match.');

        EDocumentPurchaseLine.Next();
        // Line 2: -3 x 500 EUR (negative quantity)
        Assert.AreEqual(-3, EDocumentPurchaseLine.Quantity, 'Line 2 quantity does not match (should be negative).');
        Assert.AreEqual(-1500, EDocumentPurchaseLine."Sub Total", 'Line 2 sub total does not match.');
        Assert.AreEqual('item name 2', EDocumentPurchaseLine.Description, 'Line 2 description does not match.');
        Assert.AreEqual(500, EDocumentPurchaseLine."Unit Price", 'Line 2 unit price does not match.');

        EDocumentPurchaseLine.Next();
        // Charge line: Insurance, 25 EUR, VAT 25%
        Assert.AreEqual(1, EDocumentPurchaseLine.Quantity, 'Charge line quantity should be 1.');
        Assert.AreEqual(25, EDocumentPurchaseLine."Unit Price", 'Charge line unit price does not match.');
        Assert.AreEqual(25, EDocumentPurchaseLine."Sub Total", 'Charge line sub total does not match.');
        Assert.AreEqual('Insurance', EDocumentPurchaseLine.Description, 'Charge line description does not match.');
        Assert.AreEqual(25, EDocumentPurchaseLine."VAT Rate", 'Charge line VAT rate does not match.');
    end;

    internal procedure AssertPEPPOLInvoiceWithChargesExtracted(EDocumentEntryNo: Integer)
    var
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
    begin
        EDocumentPurchaseHeader.Get(EDocumentEntryNo);
        Assert.AreEqual('INV-CHARGE-001', EDocumentPurchaseHeader."Sales Invoice No.", 'The invoice ID does not match.');
        Assert.AreEqual(DMY2Date(01, 03, 2026), EDocumentPurchaseHeader."Document Date", 'The document date does not match.');
        Assert.AreEqual(DMY2Date(01, 04, 2026), EDocumentPurchaseHeader."Due Date", 'The due date does not match.');
        Assert.AreEqual('XYZ', EDocumentPurchaseHeader."Currency Code", 'The currency code does not match.');
        Assert.AreEqual('PO-100', EDocumentPurchaseHeader."Purchase Order No.", 'The purchase order number does not match.');
        Assert.AreEqual('CRONUS International', EDocumentPurchaseHeader."Vendor Company Name", 'The vendor name does not match.');
        Assert.AreEqual(1200, EDocumentPurchaseHeader.Total, 'The total does not match.');
        Assert.AreEqual(950, EDocumentPurchaseHeader."Sub Total", 'The sub total does not match.');
        Assert.AreEqual(200, EDocumentPurchaseHeader."Total Discount", 'The total discount (allowance) does not match.');

        EDocumentPurchaseLine.SetRange("E-Document Entry No.", EDocumentEntryNo);
        Assert.AreEqual(2, EDocumentPurchaseLine.Count(), 'Expected 1 invoice line + 1 charge line (allowance should NOT create a line).');

        EDocumentPurchaseLine.FindSet();
        // Invoice line: Widget, 2 x 500 XYZ
        Assert.AreEqual(2, EDocumentPurchaseLine.Quantity, 'Invoice line quantity does not match.');
        Assert.AreEqual('PCS', EDocumentPurchaseLine."Unit of Measure", 'Invoice line unit of measure does not match.');
        Assert.AreEqual(1000, EDocumentPurchaseLine."Sub Total", 'Invoice line sub total does not match.');
        Assert.AreEqual('Widget', EDocumentPurchaseLine.Description, 'Invoice line description does not match.');
        // StandardItemIdentification (7350053850019) should override SellersItemIdentification (WIDGET-001)
        Assert.AreEqual('7350053850019', EDocumentPurchaseLine."Product Code", 'Product code should be StandardItemIdentification, not SellersItemIdentification.');
        Assert.AreEqual(25, EDocumentPurchaseLine."VAT Rate", 'Invoice line VAT rate does not match.');
        Assert.AreEqual(500, EDocumentPurchaseLine."Unit Price", 'Invoice line unit price does not match.');

        EDocumentPurchaseLine.Next();
        // Charge line: Freight charge, 150 XYZ, VAT 25%
        Assert.AreEqual(1, EDocumentPurchaseLine.Quantity, 'Charge line quantity should be 1.');
        Assert.AreEqual(150, EDocumentPurchaseLine."Unit Price", 'Charge line unit price does not match.');
        Assert.AreEqual(150, EDocumentPurchaseLine."Sub Total", 'Charge line sub total does not match.');
        Assert.AreEqual('Freight charge', EDocumentPurchaseLine.Description, 'Charge line description does not match.');
        Assert.AreEqual(25, EDocumentPurchaseLine."VAT Rate", 'Charge line VAT rate does not match.');
        Assert.AreEqual('XYZ', EDocumentPurchaseLine."Currency Code", 'Charge line currency code does not match.');
    end;

    internal procedure AssertPEPPOLVatCategorySExtracted(EDocumentEntryNo: Integer)
    var
        GLSetup: Record "General Ledger Setup";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
    begin
        GLSetup.Get();
        EDocumentPurchaseHeader.Get(EDocumentEntryNo);
        Assert.AreEqual('Snippet1', EDocumentPurchaseHeader."Sales Invoice No.", 'The invoice ID does not match.');
        Assert.AreEqual(DMY2Date(13, 11, 2017), EDocumentPurchaseHeader."Document Date", 'The document date does not match.');
        Assert.AreEqual(DMY2Date(01, 12, 2017), EDocumentPurchaseHeader."Due Date", 'The due date does not match.');
        Assert.AreEqual(ExpectedCurrencyCode('EUR', GLSetup."LCY Code"), EDocumentPurchaseHeader."Currency Code", 'The currency code does not match.');
        Assert.AreEqual('SupplierTradingName Ltd.', EDocumentPurchaseHeader."Vendor Company Name", 'The vendor name does not match.');
        Assert.AreEqual('John Doe', EDocumentPurchaseHeader."Vendor Contact Name", 'The vendor contact name does not match.');
        Assert.AreEqual('7300010000001', EDocumentPurchaseHeader."Vendor GLN", 'The vendor GLN does not match for schemeID=0088.');
        Assert.AreEqual(8550, EDocumentPurchaseHeader.Total, 'The total does not match.');
        Assert.AreEqual(7000, EDocumentPurchaseHeader."Sub Total", 'The sub total does not match.');
        Assert.AreEqual(100, EDocumentPurchaseHeader."Total Discount", 'The total discount does not match.');

        EDocumentPurchaseLine.SetRange("E-Document Entry No.", EDocumentEntryNo);
        Assert.AreEqual(4, EDocumentPurchaseLine.Count(), 'Expected 3 invoice lines + 1 charge line.');

        EDocumentPurchaseLine.FindSet();
        // Line 1: 10 x 400, VAT 25%, StandardItemIdentification overrides SellersItemIdentification
        Assert.AreEqual(10, EDocumentPurchaseLine.Quantity, 'Line 1 quantity does not match.');
        Assert.AreEqual(4000, EDocumentPurchaseLine."Sub Total", 'Line 1 sub total does not match.');
        Assert.AreEqual('item name', EDocumentPurchaseLine.Description, 'Line 1 description does not match.');
        Assert.AreEqual('7300010000001', EDocumentPurchaseLine."Product Code", 'Line 1 product code should be StandardItemIdentification.');
        Assert.AreEqual(25, EDocumentPurchaseLine."VAT Rate", 'Line 1 VAT rate does not match.');
        Assert.AreEqual(400, EDocumentPurchaseLine."Unit Price", 'Line 1 unit price does not match.');

        EDocumentPurchaseLine.Next();
        // Line 2: 10 x 200, VAT 15% (different rate)
        Assert.AreEqual(10, EDocumentPurchaseLine.Quantity, 'Line 2 quantity does not match.');
        Assert.AreEqual(2000, EDocumentPurchaseLine."Sub Total", 'Line 2 sub total does not match.');
        Assert.AreEqual(15, EDocumentPurchaseLine."VAT Rate", 'Line 2 VAT rate should be 15% (different from line 1).');
        Assert.AreEqual(200, EDocumentPurchaseLine."Unit Price", 'Line 2 unit price does not match.');

        EDocumentPurchaseLine.Next();
        // Line 3: 10 x 90, VAT 25%, StandardItemIdentification with different schemeID (0160)
        Assert.AreEqual(10, EDocumentPurchaseLine.Quantity, 'Line 3 quantity does not match.');
        Assert.AreEqual(900, EDocumentPurchaseLine."Sub Total", 'Line 3 sub total does not match.');
        Assert.AreEqual('873649827489', EDocumentPurchaseLine."Product Code", 'Line 3 product code should be StandardItemIdentification with schemeID=0160.');
        Assert.AreEqual(25, EDocumentPurchaseLine."VAT Rate", 'Line 3 VAT rate does not match.');
        Assert.AreEqual(90, EDocumentPurchaseLine."Unit Price", 'Line 3 unit price does not match.');

        EDocumentPurchaseLine.Next();
        // Charge line: Cleaning, 200 EUR, VAT 25%
        Assert.AreEqual(1, EDocumentPurchaseLine.Quantity, 'Charge line quantity should be 1.');
        Assert.AreEqual(200, EDocumentPurchaseLine."Unit Price", 'Charge line unit price does not match.');
        Assert.AreEqual('Cleaning', EDocumentPurchaseLine.Description, 'Charge line description does not match.');
        Assert.AreEqual(25, EDocumentPurchaseLine."VAT Rate", 'Charge line VAT rate does not match.');
    end;

    internal procedure AssertPEPPOLVatCategoryZExtracted(EDocumentEntryNo: Integer)
    var
        GLSetup: Record "General Ledger Setup";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
    begin
        GLSetup.Get();
        EDocumentPurchaseHeader.Get(EDocumentEntryNo);
        Assert.AreEqual('Vat-Z', EDocumentPurchaseHeader."Sales Invoice No.", 'The invoice ID does not match.');
        Assert.AreEqual(DMY2Date(30, 08, 2018), EDocumentPurchaseHeader."Document Date", 'The document date does not match.');
        Assert.AreEqual(0D, EDocumentPurchaseHeader."Due Date", 'Due Date should be blank when not present in the XML.');
        Assert.AreEqual(ExpectedCurrencyCode('GBP', GLSetup."LCY Code"), EDocumentPurchaseHeader."Currency Code", 'The currency code does not match.');
        Assert.AreEqual('The Sellercompany Incorporated', EDocumentPurchaseHeader."Vendor Company Name", 'The vendor name does not match.');
        Assert.AreEqual('GB928741974', EDocumentPurchaseHeader."Vendor VAT Id", 'The vendor VAT id does not match.');
        Assert.AreEqual('7300010000001', EDocumentPurchaseHeader."Vendor GLN", 'The vendor GLN does not match for schemeID=0088.');
        Assert.AreEqual('The Buyercompany', EDocumentPurchaseHeader."Customer Company Name", 'The customer name does not match.');
        Assert.AreEqual('', EDocumentPurchaseHeader."Customer GLN", 'Customer GLN should be empty for schemeID=0184.');
        Assert.AreEqual('0184:DK12345678', EDocumentPurchaseHeader."Customer Company Id", 'Customer Company Id should be schemeID:value.');
        Assert.AreEqual(1200, EDocumentPurchaseHeader.Total, 'The total does not match.');
        Assert.AreEqual(1200, EDocumentPurchaseHeader."Sub Total", 'The sub total does not match.');
        Assert.AreEqual(0, EDocumentPurchaseHeader."Total VAT", 'The total VAT should be 0 for zero-rated goods.');

        EDocumentPurchaseLine.SetRange("E-Document Entry No.", EDocumentEntryNo);
        Assert.AreEqual(1, EDocumentPurchaseLine.Count(), 'Expected 1 invoice line.');

        EDocumentPurchaseLine.FindFirst();
        Assert.AreEqual(10, EDocumentPurchaseLine.Quantity, 'Line quantity does not match.');
        Assert.AreEqual('EA', EDocumentPurchaseLine."Unit of Measure", 'Line unit of measure does not match.');
        Assert.AreEqual(1200, EDocumentPurchaseLine."Sub Total", 'Line sub total does not match.');
        Assert.AreEqual('Test item, category Z', EDocumentPurchaseLine.Description, 'Line description does not match.');
        Assert.AreEqual('192387129837129873', EDocumentPurchaseLine."Product Code", 'Line product code does not match.');
        Assert.AreEqual(0, EDocumentPurchaseLine."VAT Rate", 'Line VAT rate should be 0 for category Z.');
        Assert.AreEqual(120, EDocumentPurchaseLine."Unit Price", 'Line unit price does not match.');
    end;

    internal procedure AssertPEPPOLAllowanceExampleExtracted(EDocumentEntryNo: Integer)
    var
        GLSetup: Record "General Ledger Setup";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
    begin
        GLSetup.Get();
        EDocumentPurchaseHeader.Get(EDocumentEntryNo);
        Assert.AreEqual('Snippet1', EDocumentPurchaseHeader."Sales Invoice No.", 'The invoice ID does not match.');
        Assert.AreEqual(DMY2Date(13, 11, 2017), EDocumentPurchaseHeader."Document Date", 'The document date does not match.');
        Assert.AreEqual(DMY2Date(01, 12, 2017), EDocumentPurchaseHeader."Due Date", 'The due date does not match.');
        Assert.AreEqual(ExpectedCurrencyCode('EUR', GLSetup."LCY Code"), EDocumentPurchaseHeader."Currency Code", 'The currency code does not match.');
        Assert.AreEqual('SupplierTradingName Ltd.', EDocumentPurchaseHeader."Vendor Company Name", 'The vendor name does not match.');
        Assert.AreEqual('7300010000001', EDocumentPurchaseHeader."Vendor GLN", 'The vendor GLN does not match for schemeID=0088.');
        Assert.AreEqual(6125, EDocumentPurchaseHeader.Total, 'The total (PayableAmount) does not match.');
        Assert.AreEqual(5900, EDocumentPurchaseHeader."Sub Total", 'The sub total (TaxExclusiveAmount) does not match.');
        Assert.AreEqual(200, EDocumentPurchaseHeader."Total Discount", 'The total discount (AllowanceTotalAmount) does not match.');

        EDocumentPurchaseLine.SetRange("E-Document Entry No.", EDocumentEntryNo);
        // 3 invoice lines + 1 charge line (Cleaning 200 EUR); the allowance (Discount 200 EUR) should NOT create a line
        Assert.AreEqual(4, EDocumentPurchaseLine.Count(), 'Expected 3 invoice lines + 1 charge line (allowance should NOT create a line).');

        EDocumentPurchaseLine.FindSet();
        // Line 1: 10 x 410, only SellersItemIdentification (no StandardItemIdentification)
        Assert.AreEqual(10, EDocumentPurchaseLine.Quantity, 'Line 1 quantity does not match.');
        Assert.AreEqual(4000, EDocumentPurchaseLine."Sub Total", 'Line 1 sub total does not match.');
        Assert.AreEqual('item name', EDocumentPurchaseLine.Description, 'Line 1 description does not match (Name takes priority).');
        Assert.AreEqual('97iugug876', EDocumentPurchaseLine."Product Code", 'Line 1 product code should be SellersItemIdentification when no StandardItemIdentification exists.');
        Assert.AreEqual(25, EDocumentPurchaseLine."VAT Rate", 'Line 1 VAT rate does not match.');
        Assert.AreEqual(410, EDocumentPurchaseLine."Unit Price", 'Line 1 unit price does not match.');

        EDocumentPurchaseLine.Next();
        // Line 2: 10 x 200, VAT E (0%), SellersItemIdentification only
        Assert.AreEqual(10, EDocumentPurchaseLine.Quantity, 'Line 2 quantity does not match.');
        Assert.AreEqual(1000, EDocumentPurchaseLine."Sub Total", 'Line 2 sub total does not match.');
        Assert.AreEqual(0, EDocumentPurchaseLine."VAT Rate", 'Line 2 VAT rate should be 0% for category E.');
        Assert.AreEqual(200, EDocumentPurchaseLine."Unit Price", 'Line 2 unit price does not match.');

        EDocumentPurchaseLine.Next();
        // Line 3: 10 x 100, VAT 25%, SellersItemIdentification only
        Assert.AreEqual(10, EDocumentPurchaseLine.Quantity, 'Line 3 quantity does not match.');
        Assert.AreEqual(900, EDocumentPurchaseLine."Sub Total", 'Line 3 sub total does not match.');
        Assert.AreEqual(25, EDocumentPurchaseLine."VAT Rate", 'Line 3 VAT rate does not match.');
        Assert.AreEqual(100, EDocumentPurchaseLine."Unit Price", 'Line 3 unit price does not match.');

        EDocumentPurchaseLine.Next();
        // Charge line: Cleaning, 200 EUR, VAT 25%
        Assert.AreEqual(1, EDocumentPurchaseLine.Quantity, 'Charge line quantity should be 1.');
        Assert.AreEqual(200, EDocumentPurchaseLine."Unit Price", 'Charge line unit price does not match.');
        Assert.AreEqual(200, EDocumentPurchaseLine."Sub Total", 'Charge line sub total does not match.');
        Assert.AreEqual('Cleaning', EDocumentPurchaseLine.Description, 'Charge line description does not match.');
        Assert.AreEqual(25, EDocumentPurchaseLine."VAT Rate", 'Charge line VAT rate does not match.');
    end;

    internal procedure AssertPEPPOLCreditNoteCorrectionExtracted(EDocumentEntryNo: Integer)
    var
        GLSetup: Record "General Ledger Setup";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
    begin
        GLSetup.Get();
        EDocumentPurchaseHeader.Get(EDocumentEntryNo);
        Assert.AreEqual('Snippet1', EDocumentPurchaseHeader."Sales Invoice No.", 'The credit note ID does not match.');
        Assert.AreEqual(DMY2Date(13, 11, 2017), EDocumentPurchaseHeader."Document Date", 'The document date does not match.');
        // CreditNote without PaymentMeans/PaymentDueDate: DueDate should be blank
        Assert.AreEqual(0D, EDocumentPurchaseHeader."Due Date", 'Due Date should be blank when CreditNote has no PaymentMeans/PaymentDueDate.');
        Assert.AreEqual(ExpectedCurrencyCode('EUR', GLSetup."LCY Code"), EDocumentPurchaseHeader."Currency Code", 'The currency code does not match.');
        Assert.AreEqual('Snippet1', EDocumentPurchaseHeader."Vendor Invoice No.", 'The BillingReference (Vendor Invoice No.) does not match.');
        Assert.AreEqual('SupplierTradingName Ltd.', EDocumentPurchaseHeader."Vendor Company Name", 'The vendor name does not match.');
        Assert.AreEqual('GB1232434', EDocumentPurchaseHeader."Vendor VAT Id", 'The vendor VAT id does not match.');
        Assert.AreEqual(1656.25, EDocumentPurchaseHeader.Total, 'The total does not match.');
        Assert.AreEqual(1325, EDocumentPurchaseHeader."Sub Total", 'The sub total does not match.');

        EDocumentPurchaseLine.SetRange("E-Document Entry No.", EDocumentEntryNo);
        Assert.AreEqual(3, EDocumentPurchaseLine.Count(), 'Expected 2 credit note lines + 1 charge line.');

        EDocumentPurchaseLine.FindSet();
        // CreditNoteLine 1: 7 x 400
        Assert.AreEqual(7, EDocumentPurchaseLine.Quantity, 'Line 1 quantity does not match.');
        Assert.AreEqual('DAY', EDocumentPurchaseLine."Unit of Measure", 'Line 1 unit of measure does not match.');
        Assert.AreEqual(2800, EDocumentPurchaseLine."Sub Total", 'Line 1 sub total does not match.');
        Assert.AreEqual('item name', EDocumentPurchaseLine.Description, 'Line 1 description does not match.');
        Assert.AreEqual(400, EDocumentPurchaseLine."Unit Price", 'Line 1 unit price does not match.');
        Assert.AreEqual(25, EDocumentPurchaseLine."VAT Rate", 'Line 1 VAT rate does not match.');

        EDocumentPurchaseLine.Next();
        // CreditNoteLine 2: -3 x 500 (negative quantity)
        Assert.AreEqual(-3, EDocumentPurchaseLine.Quantity, 'Line 2 quantity does not match (should be negative).');
        Assert.AreEqual(-1500, EDocumentPurchaseLine."Sub Total", 'Line 2 sub total does not match.');
        Assert.AreEqual('item name 2', EDocumentPurchaseLine.Description, 'Line 2 description does not match.');
        Assert.AreEqual(500, EDocumentPurchaseLine."Unit Price", 'Line 2 unit price does not match.');

        EDocumentPurchaseLine.Next();
        // Charge line: Insurance, 25 EUR, VAT 25%
        Assert.AreEqual(1, EDocumentPurchaseLine.Quantity, 'Charge line quantity should be 1.');
        Assert.AreEqual(25, EDocumentPurchaseLine."Unit Price", 'Charge line unit price does not match.');
        Assert.AreEqual('Insurance', EDocumentPurchaseLine.Description, 'Charge line description does not match.');
        Assert.AreEqual(25, EDocumentPurchaseLine."VAT Rate", 'Charge line VAT rate does not match.');
    end;

    internal procedure AssertPEPPOLAttachmentHeaderExtracted(EDocumentEntryNo: Integer)
    var
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
    begin
        EDocumentPurchaseHeader.Get(EDocumentEntryNo);
        Assert.AreEqual('INV-ATT-001', EDocumentPurchaseHeader."Sales Invoice No.", 'The invoice ID does not match.');
        Assert.AreEqual('XYZ', EDocumentPurchaseHeader."Currency Code", 'The currency code does not match.');
        Assert.AreEqual('Attachment Supplier Ltd.', EDocumentPurchaseHeader."Vendor Company Name", 'The vendor name does not match.');
        Assert.AreEqual(625, EDocumentPurchaseHeader.Total, 'The total does not match.');
    end;

    internal procedure AssertPEPPOLDescriptionFallbackExtracted(EDocumentEntryNo: Integer)
    var
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
    begin
        EDocumentPurchaseHeader.Get(EDocumentEntryNo);
        Assert.AreEqual('INV-DESC-001', EDocumentPurchaseHeader."Sales Invoice No.", 'The invoice ID does not match.');

        EDocumentPurchaseLine.SetRange("E-Document Entry No.", EDocumentEntryNo);
        Assert.AreEqual(3, EDocumentPurchaseLine.Count(), 'Expected 3 invoice lines.');

        EDocumentPurchaseLine.FindSet();
        // Line 1: Name only - should use Name
        Assert.AreEqual('Widget Alpha', EDocumentPurchaseLine.Description, 'Line 1: Name should be used as description.');

        EDocumentPurchaseLine.Next();
        // Line 2: Description only, no Name - should fall back to Description
        Assert.AreEqual('Detailed description of Widget Beta for testing fallback', EDocumentPurchaseLine.Description, 'Line 2: Description should be used as fallback when Name is absent.');

        EDocumentPurchaseLine.Next();
        // Line 3: Both Name and Description - Name takes priority
        Assert.AreEqual('Widget Gamma', EDocumentPurchaseLine.Description, 'Line 3: Name should take priority over Description.');
    end;

    internal procedure AssertPEPPOLPayeePartyOverrideExtracted(EDocumentEntryNo: Integer)
    var
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
    begin
        EDocumentPurchaseHeader.Get(EDocumentEntryNo);
        Assert.AreEqual('INV-PAYEE-001', EDocumentPurchaseHeader."Sales Invoice No.", 'The invoice ID does not match.');
        // PayeeParty overrides AccountingSupplierParty
        Assert.AreEqual('Factoring Company GmbH', EDocumentPurchaseHeader."Vendor Company Name", 'Vendor name should be overridden by PayeeParty/PartyName.');
        Assert.AreEqual('DE999888777', EDocumentPurchaseHeader."Vendor VAT Id", 'Vendor VAT Id should be overridden by PayeeParty/PartyLegalEntity/CompanyID.');
        // Address comes from AccountingSupplierParty (PayeeParty has no address)
        Assert.AreEqual('Supplier Street 1', EDocumentPurchaseHeader."Vendor Address", 'Vendor address should still come from AccountingSupplierParty.');
        // GLN comes from AccountingSupplierParty endpoint
        Assert.AreEqual('1234567890128', EDocumentPurchaseHeader."Vendor GLN", 'Vendor GLN should still come from AccountingSupplierParty endpoint.');
        Assert.AreEqual(250, EDocumentPurchaseHeader.Total, 'The total does not match.');
    end;
    #endregion

    #region MLLM
    internal procedure AssertFullMLLMDocumentExtracted(EDocumentEntryNo: Integer)
    var
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
    begin
        EDocumentPurchaseHeader.Get(EDocumentEntryNo);

        Assert.AreEqual('MLLM-INV-001', EDocumentPurchaseHeader."Sales Invoice No.", 'The sales invoice number does not match the mock data.');
        Assert.AreEqual(DMY2Date(15, 3, 2024), EDocumentPurchaseHeader."Document Date", 'The document date does not match the mock data.');
        Assert.AreEqual(DMY2Date(15, 4, 2024), EDocumentPurchaseHeader."Due Date", 'The due date does not match the mock data.');
        Assert.AreEqual('XYZ', EDocumentPurchaseHeader."Currency Code", 'The currency code does not match the mock data.');
        Assert.AreEqual('PO-5678', EDocumentPurchaseHeader."Purchase Order No.", 'The purchase order number does not match the mock data.');
        Assert.AreEqual('Net 30', EDocumentPurchaseHeader."Payment Terms", 'The payment terms do not match the mock data.');
        Assert.AreEqual('Contoso Supplies Ltd.', EDocumentPurchaseHeader."Vendor Company Name", 'The vendor name does not match the mock data.');
        Assert.AreEqual('123 Bill Ave, Seattle 98101, US', EDocumentPurchaseHeader."Vendor Address", 'The vendor address does not match the mock data.');
        Assert.AreEqual('US-VAT-12345', EDocumentPurchaseHeader."Vendor VAT Id", 'The vendor VAT id does not match the mock data.');
        Assert.AreEqual('John Doe', EDocumentPurchaseHeader."Vendor Contact Name", 'The vendor contact name does not match the mock data.');
        Assert.AreEqual('Microsoft Corporation', EDocumentPurchaseHeader."Customer Company Name", 'The customer name does not match the mock data.');
        Assert.AreEqual('456 Main St, Redmond 98052, US', EDocumentPurchaseHeader."Customer Address", 'The customer address does not match the mock data.');
        Assert.AreEqual('US-VAT-67890', EDocumentPurchaseHeader."Customer VAT Id", 'The customer VAT id does not match the mock data.');
        Assert.AreEqual('789 Ship Rd, Bellevue 98004, US', EDocumentPurchaseHeader."Shipping Address", 'The shipping address does not match the mock data.');
        Assert.AreEqual('Warehouse Team', EDocumentPurchaseHeader."Shipping Address Recipient", 'The shipping address recipient does not match the mock data.');
        Assert.AreEqual('Contoso Billing Dept', EDocumentPurchaseHeader."Remittance Address Recipient", 'The remittance address recipient does not match the mock data.');
        Assert.AreEqual(37.5, EDocumentPurchaseHeader."Total VAT", 'The total VAT does not match the mock data.');
        Assert.AreEqual(250, EDocumentPurchaseHeader."Sub Total", 'The sub total does not match the mock data.');
        Assert.AreEqual(5, EDocumentPurchaseHeader."Total Discount", 'The total discount does not match the mock data.');
        Assert.AreEqual(287.5, EDocumentPurchaseHeader.Total, 'The total does not match the mock data.');
        Assert.AreEqual(287.5, EDocumentPurchaseHeader."Amount Due", 'The amount due does not match the mock data.');

        EDocumentPurchaseLine.SetRange("E-Document Entry No.", EDocumentEntryNo);
        EDocumentPurchaseLine.FindSet();
        Assert.AreEqual('Consulting Services', EDocumentPurchaseLine.Description, 'The description in line 1 does not match the mock data.');
        Assert.AreEqual('SVC-001', EDocumentPurchaseLine."Product Code", 'The product code in line 1 does not match the mock data.');
        Assert.AreEqual(5, EDocumentPurchaseLine.Quantity, 'The quantity in line 1 does not match the mock data.');
        Assert.AreEqual('HRS', EDocumentPurchaseLine."Unit of Measure", 'The unit of measure in line 1 does not match the mock data.');
        Assert.AreEqual(40, EDocumentPurchaseLine."Unit Price", 'The unit price in line 1 does not match the mock data.');
        Assert.AreEqual(200, EDocumentPurchaseLine."Sub Total", 'The sub total in line 1 does not match the mock data.');
        Assert.AreEqual(15, EDocumentPurchaseLine."VAT Rate", 'The VAT rate in line 1 does not match the mock data.');
        Assert.AreEqual(5, EDocumentPurchaseLine."Total Discount", 'The total discount in line 1 does not match the mock data.');

        EDocumentPurchaseLine.Next();
        Assert.AreEqual('Office Supplies', EDocumentPurchaseLine.Description, 'The description in line 2 does not match the mock data.');
        Assert.AreEqual('MAT-002', EDocumentPurchaseLine."Product Code", 'The product code in line 2 does not match the mock data.');
        Assert.AreEqual(10, EDocumentPurchaseLine.Quantity, 'The quantity in line 2 does not match the mock data.');
        Assert.AreEqual('PCS', EDocumentPurchaseLine."Unit of Measure", 'The unit of measure in line 2 does not match the mock data.');
        Assert.AreEqual(3, EDocumentPurchaseLine."Unit Price", 'The unit price in line 2 does not match the mock data.');
        Assert.AreEqual(30, EDocumentPurchaseLine."Sub Total", 'The sub total in line 2 does not match the mock data.');
        Assert.AreEqual(10, EDocumentPurchaseLine."VAT Rate", 'The VAT rate in line 2 does not match the mock data.');
        Assert.AreEqual(0, EDocumentPurchaseLine."Total Discount", 'The total discount in line 2 does not match the mock data.');

        EDocumentPurchaseLine.Next();
        Assert.AreEqual('Express Delivery', EDocumentPurchaseLine.Description, 'The description in line 3 does not match the mock data.');
        Assert.AreEqual('DLV-003', EDocumentPurchaseLine."Product Code", 'The product code in line 3 does not match the mock data.');
        Assert.AreEqual(1, EDocumentPurchaseLine.Quantity, 'The quantity in line 3 does not match the mock data.');
        Assert.AreEqual('EA', EDocumentPurchaseLine."Unit of Measure", 'The unit of measure in line 3 does not match the mock data.');
        Assert.AreEqual(20, EDocumentPurchaseLine."Unit Price", 'The unit price in line 3 does not match the mock data.');
        Assert.AreEqual(20, EDocumentPurchaseLine."Sub Total", 'The sub total in line 3 does not match the mock data.');
        Assert.AreEqual(15, EDocumentPurchaseLine."VAT Rate", 'The VAT rate in line 3 does not match the mock data.');
        Assert.AreEqual(0, EDocumentPurchaseLine."Total Discount", 'The total discount in line 3 does not match the mock data.');
    end;
    #endregion

    local procedure ExpectedCurrencyCode(DocumentCurrency: Code[10]; LCYCode: Code[10]): Code[10]
    begin
        if DocumentCurrency = LCYCode then
            exit('');
        exit(DocumentCurrency);
    end;

}
