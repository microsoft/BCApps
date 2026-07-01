// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.WIP;

enum 1035 "Job WIP Recognized Costs Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "At Completion") { Caption = 'At Completion'; }
    value(1; "Cost of Sales") { Caption = 'Cost of Sales'; }
    value(2; "Cost Value") { Caption = 'Cost Value'; }
    value(3; "Contract (Invoiced Cost)") { Caption = 'Contract (Invoiced Cost)'; }
    value(4; "Usage (Total Cost)") { Caption = 'Usage (Total Cost)'; }
}
