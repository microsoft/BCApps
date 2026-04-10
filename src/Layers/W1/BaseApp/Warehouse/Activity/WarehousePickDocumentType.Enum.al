// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Activity;

enum 7345 "Warehouse Pick Document Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(2; "Shipment") { Caption = 'Shipment'; }
    value(4; "Internal Pick") { Caption = 'Internal Pick'; }
    // Moved to enum extension "Mfg. Whse. Pick Document Type"
    // value(5; "Production") { Caption = 'Production'; }
    value(6; "Movement Worksheet") { Caption = 'Movement Worksheet'; }
    value(8; "Assembly") { Caption = 'Assembly'; }
    value(9; "Job") { Caption = 'Project'; }
}
