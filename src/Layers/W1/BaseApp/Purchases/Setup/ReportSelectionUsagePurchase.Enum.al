// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Setup;

#pragma warning disable AL0659
enum 347 "Report Selection Usage Purchase"
#pragma warning restore AL0659
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Quote") { Caption = 'Quote'; }
    value(1; "Blanket Order") { Caption = 'Blanket Order'; }
    value(2; "Order") { Caption = 'Order'; }
    value(3; "Invoice") { Caption = 'Invoice'; }
    value(4; "Return Order") { Caption = 'Return Order'; }
    value(5; "Credit Memo") { Caption = 'Credit Memo'; }
    value(6; "Receipt") { Caption = 'Receipt'; }
    value(7; "Return Shipment") { Caption = 'Return Shipment'; }
    value(8; "Purchase Document - Test") { Caption = 'Purchase Document - Test'; }
    value(9; "Prepayment Document - Test") { Caption = 'Prepayment Document - Test'; }
    value(10; "Archived Quote") { Caption = 'Archived Quote'; }
    value(11; "Archived Order") { Caption = 'Archived Order'; }
    value(12; "Archived Return Order") { Caption = 'Archived Return Order'; }
    value(13; "Archived Blanket Order") { Caption = 'Archived Blanket Order'; }
    value(14; "Vendor Remittance") { Caption = 'Vendor Remittance'; }
    value(15; "Vendor Remittance - Posted Entries") { Caption = 'Vendor Remittance - Posted Entries'; }
}
