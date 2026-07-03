// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.WIP;

enum 1036 "Job WIP Recognized Sales Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "At Completion") { Caption = 'At Completion'; }
    value(1; "Contract (Invoiced Price)") { Caption = 'Contract (Invoiced Price)'; }
    value(2; "Usage (Total Cost)") { Caption = 'Usage (Total Cost)'; }
    value(3; "Usage (Total Price)") { Caption = 'Usage (Total Price)'; }
    value(4; "Percentage of Completion") { Caption = 'Percentage of Completion'; }
    value(5; "Sales Value") { Caption = 'Sales Value'; }
}
