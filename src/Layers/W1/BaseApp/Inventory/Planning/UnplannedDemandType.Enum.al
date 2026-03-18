// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Planning;

enum 5520 "Unplanned Demand Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "Production") { Caption = 'Production'; }
    value(2; "Sales") { Caption = 'Sales'; }
    // Implemented in enum extension "Serv. Unplanned Demand Type"
    // value(3; "Service") { Caption = 'Service'; }
    value(4; "Job") { Caption = 'Project'; }
    value(5; "Assembly") { Caption = 'Assembly'; }
}
