// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Job;

enum 1619 "Job Status"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; Planning)
    {
        Caption = 'Planning';
    }
    value(1; Quote)
    {
        Caption = 'Quote';
    }
    value(2; Open)
    {
        Caption = 'Open';
    }
    value(3; Completed)
    {
        Caption = 'Completed';
    }
}
