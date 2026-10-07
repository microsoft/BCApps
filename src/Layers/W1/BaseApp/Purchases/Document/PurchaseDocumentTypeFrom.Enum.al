// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

enum 6238 "Purchase Document Type From"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Quote") { Caption = 'Quote'; }
    value(1; "Blanket Order") { Caption = 'Blanket Order'; }
    value(2; "Order") { Caption = 'Order'; }
    value(3; "Invoice") { Caption = 'Invoice'; }
    value(4; "Return Order") { Caption = 'Return Order'; }
    value(5; "Credit Memo") { Caption = 'Credit Memo'; }
    value(6; "Posted Receipt") { Caption = 'Posted Receipt'; }
    value(7; "Posted Invoice") { Caption = 'Posted Invoice'; }
    value(8; "Posted Return Shipment") { Caption = 'Posted Return Shipment'; }
    value(9; "Posted Credit Memo") { Caption = 'Posted Credit Memo'; }
    value(10; "Arch. Quote") { Caption = 'Arch. Quote'; }
    value(11; "Arch. Order") { Caption = 'Arch. Order'; }
    value(12; "Arch. Blanket Order") { Caption = 'Arch. Blanket Order'; }
    value(13; "Arch. Return Order") { Caption = 'Arch. Return Order'; }
}
