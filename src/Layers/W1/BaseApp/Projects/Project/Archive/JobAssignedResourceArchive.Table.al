// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Archive;

using Microsoft.Projects.Resources.Resource;

table 5140 "Job Assigned Resource Archive"
{
    Caption = 'Project Assigned Resource Archive';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Job No."; Code[20])
        {
            Caption = 'Project No.';
            ToolTip = 'Specifies the number of the related project.';
            Editable = false;
            NotBlank = true;
            TableRelation = "Job Archive";
        }
        field(2; "Job Task No."; Code[20])
        {
            Caption = 'Project Task No.';
            ToolTip = 'Specifies the related project task. Blank means the resource is assigned at the project level.';
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
        field(5047; "Version No."; Integer)
        {
            Caption = 'Version No.';
        }
    }

    keys
    {
        key(Key1; "Job No.", "Job Task No.", "Resource No.", "Version No.")
        {
            Clustered = true;
        }
    }

    procedure Caption(): Text
    var
        JobArchive: Record "Job Archive";
        JobTaskArchive: Record "Job Task Archive";
    begin
        JobArchive.SetLoadFields("No.", Description);
        if not JobArchive.Get("Job No.", "Version No.") then
            exit('');
        if "Job Task No." = '' then
            exit(StrSubstNo('%1 %2', JobArchive."No.", JobArchive.Description));
        JobTaskArchive.SetLoadFields("Job No.", "Job Task No.", Description);
        if not JobTaskArchive.Get("Job No.", "Job Task No.", "Version No.") then
            exit(StrSubstNo('%1 %2', JobArchive."No.", JobArchive.Description));
        exit(StrSubstNo('%1 %2 %3 %4', JobArchive."No.", JobArchive.Description, JobTaskArchive."Job Task No.", JobTaskArchive.Description));
    end;
}
