// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Job;

using Microsoft.Projects.Resources.Resource;

table 1008 "Job Assigned Resource"
{
    Caption = 'Project Assigned Resource';
    DrillDownPageID = "Job Assigned Resources";
    LookupPageID = "Job Assigned Resources";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Job No."; Code[20])
        {
            Caption = 'Project No.';
            ToolTip = 'Specifies the number of the related project.';
            NotBlank = true;
            TableRelation = Job;
        }
        field(2; "Job Task No."; Code[20])
        {
            Caption = 'Project Task No.';
            ToolTip = 'Specifies the related project task. Leave blank to assign the resource at the project level.';
            TableRelation = "Job Task"."Job Task No." where("Job No." = field("Job No."), "Job Task Type" = const(Posting));

            trigger OnValidate()
            begin
                CheckJobTaskIsPosting();
            end;
        }
        field(3; "Resource No."; Code[20])
        {
            Caption = 'Resource No.';
            ToolTip = 'Specifies the resource that is assigned to the project or project task.';
            NotBlank = true;
            TableRelation = Resource;
        }
        field(4; "Resource Name"; Text[100])
        {
            Caption = 'Resource Name';
            ToolTip = 'Specifies the name of the assigned resource.';
            FieldClass = FlowField;
            CalcFormula = lookup(Resource.Name where("No." = field("Resource No.")));
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Job No.", "Job Task No.", "Resource No.")
        {
            Clustered = true;
        }
        key(ResourceNo; "Resource No.")
        {
        }
    }

    trigger OnInsert()
    begin
        CheckAssignment();
    end;

    trigger OnModify()
    begin
        CheckAssignment();
    end;

    local procedure CheckAssignment()
    begin
        TestField("Job No.");
        TestField("Resource No.");
        CheckJobTaskIsPosting();
    end;

    local procedure CheckJobTaskIsPosting()
    var
        JobTask: Record "Job Task";
    begin
        // A blank Project Task No. is a project-level assignment
        if "Job Task No." = '' then
            exit;
        JobTask.SetLoadFields("Job Task Type");
        JobTask.Get("Job No.", "Job Task No.");
        JobTask.TestField("Job Task Type", JobTask."Job Task Type"::Posting);
    end;

    procedure Caption(): Text
    var
        Job: Record Job;
        JobTask: Record "Job Task";
    begin
        Job.SetLoadFields("No.", Description);
        if not Job.Get("Job No.") then
            exit('');
        if "Job Task No." = '' then
            exit(StrSubstNo('%1 %2', Job."No.", Job.Description));
        JobTask.SetLoadFields("Job No.", "Job Task No.", Description);
        if not JobTask.Get("Job No.", "Job Task No.") then
            exit(StrSubstNo('%1 %2', Job."No.", Job.Description));
        exit(StrSubstNo('%1 %2 %3 %4', Job."No.", Job.Description, JobTask."Job Task No.", JobTask.Description));
    end;
}
