// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Activity;

#pragma warning disable AL0659
enum 5768 "Warehouse Activity Source Document"
#pragma warning restore AL0659
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "Sales Order") { Caption = 'Sales Order'; }
    value(4; "Sales Return Order") { Caption = 'Sales Return Order'; }
    value(5; "Purchase Order") { Caption = 'Purchase Order'; }
    value(8; "Purchase Return Order") { Caption = 'Purchase Return Order'; }
    value(9; "Inbound Transfer") { Caption = 'Inbound Transfer'; }
    value(10; "Outbound Transfer") { Caption = 'Outbound Transfer'; }
    value(11; "Prod. Consumption") { Caption = 'Prod. Consumption'; }
    value(12; "Prod. Output") { Caption = 'Prod. Output'; }
    // Implemented in enum extension Serv. Whse. Act. Source Doc.
    // value(18; "Service Order") { Caption = 'Service Order'; }
    // Implemented in enum extension Asm. Whse. Act. Source Doc.
    // value(20; "Assembly Consumption") { Caption = 'Assembly Consumption'; }
    // value(21; "Assembly Order") { Caption = 'Assembly Order'; }
    value(22; "Job Usage") { Caption = 'Project Usage'; }
}
