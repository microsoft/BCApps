// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Document;

#pragma warning disable AL0659
enum 7323 "Warehouse Shipment Posted Source Document"
#pragma warning restore AL0659
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "Posted Receipt") { Caption = 'Posted Receipt'; }
    value(3; "Posted Return Receipt") { Caption = 'Posted Return Receipt'; }
    value(5; "Posted Shipment") { Caption = 'Posted Shipment'; }
    value(7; "Posted Return Shipment") { Caption = 'Posted Return Shipment'; }
    value(9; "Posted Transfer Receipt") { Caption = 'Posted Transfer Receipt'; }
    value(10; "Posted Transfer Shipment") { Caption = 'Posted Transfer Shipment'; }
}
