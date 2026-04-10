// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Integration.Graph;

enumextension 5050 "Asm. Doc.Att.Ent.Buf.Doc.Type" extends "Attachment Entity Buffer Document Type"
{
    value(33; "Assembly Order") { Caption = 'Assembly Order'; Implementation = IPdfDocumentHandler = "Asm. Order PDF Doc.Handler"; }
    value(34; "Posted Assembly Order") { Caption = 'Posted Assembly Order'; Implementation = IPdfDocumentHandler = "P.Asm. Order PDF Doc.Handler"; }
}
