// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Planning;

enum 1003 "Job Planning Line Line Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Budget") { Caption = 'Budget'; }
    value(1; "Billable") { Caption = 'Billable'; }
    value(2; "Both Budget and Billable") { Caption = 'Both Budget and Billable'; }
}
