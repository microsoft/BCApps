// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Graph;

using Microsoft.EServices.EDocument;

#pragma warning disable AL0659
enum 135 "Attachment Entity Buffer Document Type" implements IPdfDocumentHandler
#pragma warning restore AL0659
{
    Extensible = true;
    DefaultImplementation = IPdfDocumentHandler = "Default PDF Doc.Handler";

    value(0; " ") { Caption = ' '; }
    value(1; "Journal") { Caption = 'Journal'; }
    value(2; "Sales Order") { Caption = 'Sales Order'; Implementation = IPdfDocumentHandler = "Sales Order PDF Doc.Handler"; }
    value(3; "Sales Quote") { Caption = 'Sales Quote'; Implementation = IPdfDocumentHandler = "Sales Quote PDF Doc.Handler"; }
    value(4; "Sales Credit Memo") { Caption = 'Sales Credit Memo'; Implementation = IPdfDocumentHandler = "Sales Cr.Memo PDF Doc.Handler"; }
    value(5; "Sales Invoice") { Caption = 'Sales Invoice'; Implementation = IPdfDocumentHandler = "Sales Invoice PDF Doc.Handler"; }
    value(6; "Purchase Invoice") { Caption = 'Purchase Invoice'; Implementation = IPdfDocumentHandler = "Purch. Invoice PDF Doc.Handler"; }
    value(7; "Purchase Order") { Caption = 'Purchase Order'; Implementation = IPdfDocumentHandler = "Purch. Order PDF Doc.Handler"; }
    value(8; "Purchase Quote") { Caption = 'Purchase Quote'; Implementation = IPdfDocumentHandler = "Purch. Quote PDF Doc.Handler"; }
    value(9; "Employee") { Caption = 'Employee'; }
    value(10; "Job") { Caption = 'Project'; Implementation = IPdfDocumentHandler = "Project PDF Doc.Handler"; }
    value(11; "Item") { Caption = 'Item'; }
    value(12; "Customer") { Caption = 'Customer'; }
    value(13; "Vendor") { Caption = 'Vendor'; }
    value(14; "Purchase Credit Memo") { Caption = 'Purchase Credit Memo'; Implementation = IPdfDocumentHandler = "Purch. Cr.Memo PDF Doc.Handler"; }
    value(15; "Customer Statement") { Caption = 'Customer Statement'; Implementation = IPdfDocumentHandler = "Cust. St. PDF Doc.Handler"; }
    value(16; "Blanket Sales Order") { Caption = 'Blanket Sales Order'; Implementation = IPdfDocumentHandler = "Bl. S. Order PDF Doc.Handler"; }
    value(17; "Sales Return Order") { Caption = 'Sales Return Order'; Implementation = IPdfDocumentHandler = "S. Ret. Order PDF Doc.Handler"; }
    value(18; "Sales Shipment") { Caption = 'Sales Shipment'; Implementation = IPdfDocumentHandler = "Sales Shipment PDF Doc.Handler"; }
    value(19; "Return Receipt") { Caption = 'Return Receipt'; Implementation = IPdfDocumentHandler = "Return Receipt PDF Doc.Handler"; }
    value(20; "Blanket Purchase Order") { Caption = 'Blanket Purchase Order'; Implementation = IPdfDocumentHandler = "Bl. P. Order PDF Doc.Handler"; }
    value(21; "Purchase Receipt") { Caption = 'Purchase Receipt'; Implementation = IPdfDocumentHandler = "Purch. Rcpt. PDF Doc.Handler"; }
    value(22; "Purchase Return Order") { Caption = 'Purchase Return Order'; Implementation = IPdfDocumentHandler = "P. Ret. Order PDF Doc.Handler"; }
    value(23; "Purch. Return Shipment") { Caption = 'Purch. Return Shipment'; Implementation = IPdfDocumentHandler = "Return Shpt. PDF Doc.Handler"; }
    value(24; "Transfer Order") { Caption = 'Transfer Order'; }
    value(25; "Transfer Shipment") { Caption = 'Transfer Shipment'; }
    value(26; "Transfer Receipt") { Caption = 'Transfer Receipt'; }
    value(27; "Sales Archive Quote") { Caption = 'Sales Archive Quote'; }
    value(28; "Sales Archive Order") { Caption = 'Sales Archive Order'; }
    value(29; "Purchase Archive Quote") { Caption = 'Purchase Archive Quote'; }
    value(30; "Purchase Archive Order") { Caption = 'Purchase Archive Order'; }
    value(31; "Sales Archive Return") { Caption = 'Sales Archive Return'; }
    value(32; "Purchase Archive Return") { Caption = 'Purchase Archive Return'; }
    value(33; "Assembly Order") { Caption = 'Assembly Order'; }
    value(34; "Posted Assembly Order") { Caption = 'Posted Assembly Order'; }
    value(35; "Sales Archive Blanket Order") { Caption = 'Sales Archive Blanket Order'; }
    value(36; "Purchase Archive Blanket Order") { Caption = 'Purchase Archive Blanket Order'; }
    value(37; "Phys. Inventory Order") { Caption = 'Phys. Inventory Order'; }
    value(38; "Posted Phys. Inventory Order") { Caption = 'Posted Phys. Inventory Order'; }
    value(39; "Phys. Inventory Recording") { Caption = 'Phys. Inventory Recording'; }
    value(40; "Posted Phys. Inventory Recording") { Caption = 'Posted Phys. Inventory Recording'; }
    value(41; "Inventory Shipment") { Caption = 'Inventory Shipment'; }
    value(42; "Inventory Receipt") { Caption = 'Inventory Receipt'; }
    value(43; "Posted Inventory Shipment") { Caption = 'Posted Inventory Shipment'; }
    value(44; "Posted Inventory Receipt") { Caption = 'Posted Inventory Receipt'; }
    value(45; "Posted Direct Transfer") { Caption = 'Posted Direct Transfer'; }
}