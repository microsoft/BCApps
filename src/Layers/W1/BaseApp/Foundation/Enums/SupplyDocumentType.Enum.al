// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Enums;

enum 780 "Supply Document Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Sales Shipment") { Caption = 'Sales Shipment'; }
    value(2; "Return Shipment") { Caption = 'Return Shipment'; }
}
