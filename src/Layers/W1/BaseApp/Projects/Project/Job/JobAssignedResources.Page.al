// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Job;

page 1044 "Job Assigned Resources"
{
    Caption = 'Project Assigned Resources';
    PageType = List;
    ApplicationArea = Jobs;
    SourceTable = "Job Assigned Resource";
    DelayedInsert = true;
    DataCaptionExpression = Rec.Caption();

    layout
    {
        area(content)
        {
            repeater(AssignedResources)
            {
                field("Job No."; Rec."Job No.")
                {
                    ApplicationArea = Jobs;
                    Visible = ShowKeyColumns;
                }
                field("Job Task No."; Rec."Job Task No.")
                {
                    ApplicationArea = Jobs;
                    Visible = ShowKeyColumns;
                }
                field("Resource No."; Rec."Resource No.")
                {
                    ApplicationArea = Jobs;

                    trigger OnValidate()
                    begin
                        Rec.CalcFields("Resource Name");
                    end;
                }
                field("Resource Name"; Rec."Resource Name")
                {
                    ApplicationArea = Jobs;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        // Hide the corresponding key column when the page is opened in a project/task scope.
        ShowKeyColumns := Rec.GetFilter("Job No.") = '';
    end;

    procedure SetJobTaskContext(JobTask: Record "Job Task"): Boolean
    var
        JobAssignedResource: Record "Job Assigned Resource";
    begin
        if JobTask."Job Task Type" <> JobTask."Job Task Type"::Posting then begin
            Message(AssignOnlyToPostingTaskMsg);
            exit(false);
        end;
        JobAssignedResource.SetRange("Job No.", JobTask."Job No.");
        JobAssignedResource.SetRange("Job Task No.", JobTask."Job Task No.");
        SetTableView(JobAssignedResource);
        exit(true);
    end;

    var
        ShowKeyColumns: Boolean;
        AssignOnlyToPostingTaskMsg: Label 'Assigned resources can only be added to posting-type project tasks.';
}
