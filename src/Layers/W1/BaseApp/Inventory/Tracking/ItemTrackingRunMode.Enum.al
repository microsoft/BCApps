// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

enum 6510 "Item Tracking Run Mode"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "") { }
    value(1; "Reclass") { }
    value(2; "Combined Ship/Rcpt") { }
    value(3; "Drop Shipment") { }
    value(4; "Transfer") { }
}
