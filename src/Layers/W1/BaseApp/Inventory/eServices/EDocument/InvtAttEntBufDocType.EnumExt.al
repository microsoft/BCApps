// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Integration.Graph;

enumextension 5051 "Invt.Att.Ent.Buf.Doc.Type" extends "Attachment Entity Buffer Document Type"
{
    value(24; "Transfer Order") { Caption = 'Transfer Order'; Implementation = IPdfDocumentHandler = "Trans. Order PDF Doc.Handler"; }
    value(25; "Transfer Shipment") { Caption = 'Transfer Shipment'; Implementation = IPdfDocumentHandler = "Trans. Shpt. PDF Doc.Handler"; }
    value(26; "Transfer Receipt") { Caption = 'Transfer Receipt'; Implementation = IPdfDocumentHandler = "Trans. Rcpt. PDF Doc.Handler"; }
    value(37; "Phys. Inventory Order") { Caption = 'Phys. Inventory Order'; Implementation = IPdfDocumentHandler = "Phys.Inv.Ord. PDF Doc.Handler"; }
    value(38; "Posted Phys. Inventory Order") { Caption = 'Posted Phys. Inventory Order'; Implementation = IPdfDocumentHandler = "P.Phys.InvOrd PDF Doc.Handler"; }
    value(39; "Phys. Inventory Recording") { Caption = 'Phys. Inventory Recording'; Implementation = IPdfDocumentHandler = "Phys.Inv.Rec. PDF Doc.Handler"; }
    value(40; "Posted Phys. Inventory Recording") { Caption = 'Posted Phys. Inventory Recording'; Implementation = IPdfDocumentHandler = "P.Phys.InvRec PDF Doc.Handler"; }
    value(41; "Inventory Shipment") { Caption = 'Inventory Shipment'; Implementation = IPdfDocumentHandler = "Inv. Shpt. PDF Doc.Handler"; }
    value(42; "Inventory Receipt") { Caption = 'Inventory Receipt'; Implementation = IPdfDocumentHandler = "Inv. Rcpt. PDF Doc.Handler"; }
    value(43; "Posted Inventory Shipment") { Caption = 'Posted Inventory Shipment'; Implementation = IPdfDocumentHandler = "P.Inv. Shpt. PDF Doc.Handler"; }
    value(44; "Posted Inventory Receipt") { Caption = 'Posted Inventory Receipt'; Implementation = IPdfDocumentHandler = "P.Inv. Rcpt. PDF Doc.Handler"; }
    value(45; "Posted Direct Transfer") { Caption = 'Posted Direct Transfer'; Implementation = IPdfDocumentHandler = "P.Direct Trans PDF Doc.Handler"; }
}
