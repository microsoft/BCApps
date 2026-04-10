// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

#pragma warning disable AL0659
enum 5805 "Purchase Applies-to Document Type"
#pragma warning restore AL0659
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Quote") { Caption = 'Quote'; }
    value(1; "Order") { Caption = 'Order'; }
    value(2; "Invoice") { Caption = 'Invoice'; }
    value(3; "Credit Memo") { Caption = 'Credit Memo'; }
    value(4; "Blanket Order") { Caption = 'Blanket Order'; }
    value(5; "Return Order") { Caption = 'Return Order'; }
    value(6; "Receipt") { Caption = 'Receipt'; }
    value(7; "Transfer Receipt") { Caption = 'Transfer Receipt'; }
    value(8; "Return Shipment") { Caption = 'Return Shipment'; }
    value(9; "Sales Shipment") { Caption = 'Sales Shipment'; }
    value(10; "Return Receipt") { Caption = 'Return Receipt'; }
}
