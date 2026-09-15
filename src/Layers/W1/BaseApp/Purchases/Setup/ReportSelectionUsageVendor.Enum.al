// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Setup;

enum 9658 "Report Selection Usage Vendor"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Purchase Order") { Caption = 'Purchase Order'; }
    value(1; "Vendor Remittance") { Caption = 'Vendor Remittance'; }
    value(2; "Vendor Remittance - Posted Entries") { Caption = 'Vendor Remittance - Posted Entries'; }
    value(3; "Posted Return Shipment") { Caption = 'Posted Return Shipment'; }
}
