// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Requisition;

enum 5523 "Demand Order Source Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "All Demands") { Caption = 'All Demands'; }
    value(1; "Production Demand") { Caption = 'Production Demand'; }
    value(2; "Sales Demand") { Caption = 'Sales Demand'; }
    value(3; "Service Demand") { Caption = 'Service Demand'; }
    value(4; "Job Demand") { Caption = 'Project Demand'; }
    value(5; "Assembly Demand") { Caption = 'Assembly Demand'; }
}
