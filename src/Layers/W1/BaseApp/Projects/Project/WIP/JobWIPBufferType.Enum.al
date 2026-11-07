// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.WIP;

enum 1018 "Job WIP Buffer Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Applied Costs") { Caption = 'Applied Costs'; }
    value(1; "Applied Sales") { Caption = 'Applied Sales'; }
    value(2; "Recognized Costs") { Caption = 'Recognized Costs'; }
    value(3; "Recognized Sales") { Caption = 'Recognized Sales'; }
    value(4; "Accrued Costs") { Caption = 'Accrued Costs'; }
    value(5; "Accrued Sales") { Caption = 'Accrued Sales'; }
}
