// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Outlook;

using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Project.Planning;

table 1615 "Office Job Journal"
{
    Caption = 'Office Project Journal';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Job No."; Code[20])
        {
            Caption = 'Project No.';
            ToolTip = 'Specifies the number of the related project.';
        }
        field(2; "Job Task No."; Code[20])
        {
            Caption = 'Project Task No.';
            ToolTip = 'Specifies the number of the related project task.';
        }
        field(3; "Job Planning Line No."; Integer)
        {
            Caption = 'Project Planning Line No.';
        }
        field(4; "Job Journal Template Name"; Code[10])
        {
            Caption = 'Project Journal Template Name';
            ToolTip = 'Specifies the journal template that is used for the project journal.';
            TableRelation = "Job Journal Template".Name where("Page ID" = const(201),
                                                               Recurring = const(false));
        }
        field(5; "Job Journal Batch Name"; Code[10])
        {
            Caption = 'Project Journal Batch Name';
            ToolTip = 'Specifies the journal batch that is used for the project journal.';
            TableRelation = "Job Journal Batch".Name where("Journal Template Name" = field("Job Journal Template Name"));
        }
    }

    keys
    {
        key(Key1; "Job No.", "Job Task No.", "Job Planning Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure Initialize(JobPlanningLine: Record "Job Planning Line")
    begin
        "Job No." := JobPlanningLine."Job No.";
        "Job Task No." := JobPlanningLine."Job Task No.";
        "Job Planning Line No." := JobPlanningLine."Line No.";
    end;
}

