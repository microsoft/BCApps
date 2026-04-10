// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Integration.Graph;

enumextension 5053 "Purchase Att.Ent.Buf.Doc.Type" extends "Attachment Entity Buffer Document Type"
{
    value(6; "Purchase Invoice") { Caption = 'Purchase Invoice'; Implementation = IPdfDocumentHandler = "Purch. Invoice PDF Doc.Handler"; }
    value(7; "Purchase Order") { Caption = 'Purchase Order'; Implementation = IPdfDocumentHandler = "Purch. Order PDF Doc.Handler"; }
    value(8; "Purchase Quote") { Caption = 'Purchase Quote'; Implementation = IPdfDocumentHandler = "Purch. Quote PDF Doc.Handler"; }
    value(14; "Purchase Credit Memo") { Caption = 'Purchase Credit Memo'; Implementation = IPdfDocumentHandler = "Purch. Cr.Memo PDF Doc.Handler"; }
    value(20; "Blanket Purchase Order") { Caption = 'Blanket Purchase Order'; Implementation = IPdfDocumentHandler = "Bl. P. Order PDF Doc.Handler"; }
    value(21; "Purchase Receipt") { Caption = 'Purchase Receipt'; Implementation = IPdfDocumentHandler = "Purch. Rcpt. PDF Doc.Handler"; }
    value(22; "Purchase Return Order") { Caption = 'Purchase Return Order'; Implementation = IPdfDocumentHandler = "P. Ret. Order PDF Doc.Handler"; }
    value(23; "Purch. Return Shipment") { Caption = 'Purch. Return Shipment'; Implementation = IPdfDocumentHandler = "Return Shpt. PDF Doc.Handler"; }
    value(29; "Purchase Archive Quote") { Caption = 'Purchase Archive Quote'; Implementation = IPdfDocumentHandler = "P.Arch.Quote PDF Doc.Handler"; }
    value(30; "Purchase Archive Order") { Caption = 'Purchase Archive Order'; Implementation = IPdfDocumentHandler = "P.Arch.Order PDF Doc.Handler"; }
    value(32; "Purchase Archive Return") { Caption = 'Purchase Archive Return'; Implementation = IPdfDocumentHandler = "P.Arch.Return PDF Doc.Handler"; }
    value(36; "Purchase Archive Blanket Order") { Caption = 'Purchase Archive Blanket Order'; Implementation = IPdfDocumentHandler = "P.Arch.Bl.Ord PDF Doc.Handler"; }
}
