// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

#pragma warning disable AL0659
enum 136 "Dimension Set Entry Buffer Parent Type"
#pragma warning restore AL0659
{
    Extensible = true;

    value(0; " ") { Caption = ' '; }
    value(1; "Journal Line") { Caption = 'Journal Line'; }
    value(2; "Sales Order") { Caption = 'Sales Order'; }
    value(3; "Sales Order Line") { Caption = 'Sales Order Line'; }
    value(4; "Sales Quote") { Caption = 'Sales Quote'; }
    value(5; "Sales Quote Line") { Caption = 'Sales Quote Line'; }
    value(6; "Sales Credit Memo") { Caption = 'Sales Credit Memo'; }
    value(7; "Sales Credit Memo Line") { Caption = 'Sales Credit Memo Line'; }
    value(8; "Sales Invoice") { Caption = 'Sales Invoice'; }
    value(9; "Sales Invoice Line") { Caption = 'Sales Invoice Line'; }
    value(10; "Purchase Invoice") { Caption = 'Purchase Invoice'; }
    value(11; "Purchase Invoice Line") { Caption = 'Purchase Invoice Line'; }
    value(12; "General Ledger Entry") { Caption = 'General Ledger Entry'; }
    value(13; "Time Registration Entry") { Caption = 'Time Registration Entry'; }
    value(14; "Sales Shipment") { Caption = 'Sales Shipment'; }
    value(15; "Sales Shipment Line") { Caption = 'Sales Shipment Line'; }
    value(16; "Purchase Receipt") { Caption = 'Purchase Receipt'; }
    value(17; "Purchase Receipt Line") { Caption = 'Purchase Receipt Line'; }
    value(18; "Purchase Order") { Caption = 'Purchase Order'; }
    value(19; "Purchase Order Line") { Caption = 'Purchase Order Line'; }
    value(20; "Purchase Credit Memo") { Caption = 'Purchase Credit Memo'; }
    value(21; "Purchase Credit Memo Line") { Caption = 'Purchase Credit Memo Line'; }
}
