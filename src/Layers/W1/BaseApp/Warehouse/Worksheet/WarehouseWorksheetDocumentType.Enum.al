// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Worksheet;

#pragma warning disable AL0659
enum 5772 "Warehouse Worksheet Document Type"
#pragma warning restore AL0659
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "Receipt") { Caption = 'Receipt'; }
    value(2; "Shipment") { Caption = 'Shipment'; }
    value(3; "Internal Put-away") { Caption = 'Internal Put-away'; }
    value(4; "Internal Pick") { Caption = 'Internal Pick'; }
    value(5; "Production") { Caption = 'Production'; }
    value(6; "Whse. Mov.-Worksheet") { Caption = 'Whse. Mov.-Worksheet'; }
    value(7; "Internal Movement") { Caption = 'Internal Movement'; }
    value(8; "Assembly") { Caption = 'Assembly'; }
    value(9; "Job") { Caption = 'Project'; }
}
