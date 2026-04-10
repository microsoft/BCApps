// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Navigate;

enum 6560 "Document Line Source Type"
{
    Extensible = true;

    value(0; "Sales Order") { Caption = 'Sales Order'; }
    value(1; "Purchase Order") { Caption = 'Purchase Order'; }
    value(2; "Blanket Sales Order") { Caption = 'Blanket Sales Order'; }
    value(3; "Blanket Purchase Order") { Caption = 'Blanket Purchase Order'; }
    value(4; "Sales Shipment") { Caption = 'Sales Shipment'; }
    value(5; "Purchase Receipt") { Caption = 'Purchase Receipt'; }
    value(6; "Sales Invoice") { Caption = 'Sales Invoice'; }
    value(7; "Purchase Invoice") { Caption = 'Purchase Invoice'; }
    value(8; "Sales Return Order") { Caption = 'Sales Return Order'; }
    value(9; "Purchase Return Order") { Caption = 'Purchase Return Order'; }
    value(10; "Sales Credit Memo") { Caption = 'Sales Credit Memo'; }
    value(11; "Purchase Credit Memo") { Caption = 'Purchase Credit Memo'; }
    value(12; "Return Receipt") { Caption = 'Return Receipt'; }
    value(13; "Return Shipment") { Caption = 'Return Shipment'; }
}
