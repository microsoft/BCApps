// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Job;

enum 1002 "Job Line Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "Budget") { Caption = 'Budget'; }
    value(2; "Billable") { Caption = 'Billable'; }
    value(3; "Both Budget and Billable") { Caption = 'Both Budget and Billable'; }
}
