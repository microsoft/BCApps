// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Projects.Project.Job;

table 7088 "Expense Project Buf"
{
    Access = Internal;
    TableType = Temporary;
    Caption = 'Expense Project Buffer';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Expense User SystemId"; Guid)
        {
            Caption = 'Expense User System Id';
        }
        field(2; "Project No."; Code[20])
        {
            Caption = 'Project No.';
        }
        field(3; "Project Task No."; Code[20])
        {
            Caption = 'Project Task No.';
        }
        field(10; "Project SystemId"; Guid)
        {
            Caption = 'Project System Id';
        }
        field(11; "Project Description"; Text[100])
        {
            Caption = 'Project Description';
        }
        field(12; "Project Status"; Enum "Job Status")
        {
            Caption = 'Project Status';
        }
        field(13; "Project Starting Date"; Date)
        {
            Caption = 'Project Starting Date';
        }
        field(14; "Project Ending Date"; Date)
        {
            Caption = 'Project Ending Date';
        }
        field(20; "Task SystemId"; Guid)
        {
            Caption = 'Task System Id';
        }
        field(21; "Task Description"; Text[100])
        {
            Caption = 'Task Description';
        }
        field(22; "Task Type"; Enum "Job Task Type")
        {
            Caption = 'Task Type';
        }
        field(23; "Task Start Date"; Date)
        {
            Caption = 'Task Start Date';
        }
        field(24; "Task End Date"; Date)
        {
            Caption = 'Task End Date';
        }
    }

    keys
    {
        key(PK; "Expense User SystemId", "Project No.", "Project Task No.")
        {
            Clustered = true;
        }
    }
}
