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

}
