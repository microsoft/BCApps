// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Document;

enum 7320 "Warehouse Shipment Status"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "Partially Picked") { Caption = 'Partially Picked'; }
    value(2; "Partially Shipped") { Caption = 'Partially Shipped'; }
    value(3; "Completely Picked") { Caption = 'Completely Picked'; }
    value(4; "Completely Shipped") { Caption = 'Completely Shipped'; }
}
