// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Job;

enum 1001 "Job Task Type"
{
    AssignmentCompatibility = true;
    Extensible = true;

    value(0; Posting)
    {
        Caption = 'Posting';
    }
    value(1; Heading)
    {
        Caption = 'Heading';
    }
    value(2; Total)
    {
        Caption = 'Total';
    }
    value(3; "Begin-Total")
    {
        Caption = 'Begin-Total';
    }
    value(4; "End-Total")
    {
        Caption = 'End-Total';
    }
}
