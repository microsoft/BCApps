// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Document;

enum 5851 "Invt. Doc. Document Type From"
{
    Extensible = true;

    value(0; "Receipt") { Caption = 'Receipt'; }
    value(1; "Shipment") { Caption = 'Shipment'; }
    value(2; "Posted Receipt") { Caption = 'Posted Receipt'; }
    value(3; "Posted Shipment") { Caption = 'Posted Shipment'; }
}
