// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.TimeSheet;

enum 950 "Time Sheet Status"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; Open)
    {
        Caption = 'Open';
    }
    value(1; Submitted)
    {
        Caption = 'Submitted';
    }
    value(2; Rejected)
    {
        Caption = 'Rejected';
    }
    value(3; Approved)
    {
        Caption = 'Approved';
    }
}
