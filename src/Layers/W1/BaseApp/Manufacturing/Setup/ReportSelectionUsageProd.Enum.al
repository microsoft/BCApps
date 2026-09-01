// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Setup;

enum 99000917 "Report Selection Usage Prod."
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Job Card") { Caption = 'Job Card'; }
    value(1; "Mat. & Requisition") { Caption = 'Mat. & Requisition'; }
    value(2; "Shortage List") { Caption = 'Shortage List'; }
    value(3; "Gantt Chart") { Caption = 'Gantt Chart'; }
    value(4; "Prod. Order") { Caption = 'Prod. Order - Planning Worksheet'; }
    value(5; "Prod. Output Item Label") { Caption = 'Prod. Output Item Label'; }
}
