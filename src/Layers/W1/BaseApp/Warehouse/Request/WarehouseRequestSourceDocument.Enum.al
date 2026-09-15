// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Request;

#pragma warning disable AL0659
enum 5770 "Warehouse Request Source Document"
#pragma warning restore AL0659
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(1; "Sales Order") { Caption = 'Sales Order'; }
    value(4; "Sales Return Order") { Caption = 'Sales Return Order'; }
    value(5; "Purchase Order") { Caption = 'Purchase Order'; }
    value(8; "Purchase Return Order") { Caption = 'Purchase Return Order'; }
    value(9; "Inbound Transfer") { Caption = 'Inbound Transfer'; }
    value(10; "Outbound Transfer") { Caption = 'Outbound Transfer'; }
    // Implemented in enum extension Mfg. Whse. Req. Source Doc.
    // value(11; "Prod. Consumption") { Caption = 'Prod. Consumption'; }
    // value(12; "Prod. Output") { Caption = 'Prod. Output'; }
    // Implemented in enum extension Serv. Whse. Req. Source Doc.
    // value(13; "Service Order") { Caption = 'Service Order'; }
    // Implemented in enum extension Asm. Whse. Req. Source Doc.
    // value(20; "Assembly Consumption") { Caption = 'Assembly Consumption'; }
    // value(21; "Assembly Order") { Caption = 'Assembly Order'; }
    value(22; "Job Usage") { Caption = 'Project Usage'; }
}
