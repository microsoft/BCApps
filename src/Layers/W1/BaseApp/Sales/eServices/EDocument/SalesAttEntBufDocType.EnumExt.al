// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Integration.Graph;

enumextension 5054 "Sales Att.Ent.Buf.Doc.Type" extends "Attachment Entity Buffer Document Type"
{
    value(2; "Sales Order") { Caption = 'Sales Order'; Implementation = IPdfDocumentHandler = "Sales Order PDF Doc.Handler"; }
    value(3; "Sales Quote") { Caption = 'Sales Quote'; Implementation = IPdfDocumentHandler = "Sales Quote PDF Doc.Handler"; }
    value(4; "Sales Credit Memo") { Caption = 'Sales Credit Memo'; Implementation = IPdfDocumentHandler = "Sales Cr.Memo PDF Doc.Handler"; }
    value(5; "Sales Invoice") { Caption = 'Sales Invoice'; Implementation = IPdfDocumentHandler = "Sales Invoice PDF Doc.Handler"; }
    value(15; "Customer Statement") { Caption = 'Customer Statement'; Implementation = IPdfDocumentHandler = "Cust. St. PDF Doc.Handler"; }
    value(16; "Blanket Sales Order") { Caption = 'Blanket Sales Order'; Implementation = IPdfDocumentHandler = "Bl. S. Order PDF Doc.Handler"; }
    value(17; "Sales Return Order") { Caption = 'Sales Return Order'; Implementation = IPdfDocumentHandler = "S. Ret. Order PDF Doc.Handler"; }
    value(18; "Sales Shipment") { Caption = 'Sales Shipment'; Implementation = IPdfDocumentHandler = "Sales Shipment PDF Doc.Handler"; }
    value(19; "Return Receipt") { Caption = 'Return Receipt'; Implementation = IPdfDocumentHandler = "Return Receipt PDF Doc.Handler"; }
    value(27; "Sales Archive Quote") { Caption = 'Sales Archive Quote'; Implementation = IPdfDocumentHandler = "S.Arch.Quote PDF Doc.Handler"; }
    value(28; "Sales Archive Order") { Caption = 'Sales Archive Order'; Implementation = IPdfDocumentHandler = "S.Arch.Order PDF Doc.Handler"; }
    value(31; "Sales Archive Return") { Caption = 'Sales Archive Return'; Implementation = IPdfDocumentHandler = "S.Arch.Return PDF Doc.Handler"; }
    value(35; "Sales Archive Blanket Order") { Caption = 'Sales Archive Blanket Order'; Implementation = IPdfDocumentHandler = "S.Arch.Bl.Ord PDF Doc.Handler"; }
}
