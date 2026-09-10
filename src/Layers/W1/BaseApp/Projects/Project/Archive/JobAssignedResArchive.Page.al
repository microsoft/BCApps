// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Archive;

page 1045 "Job Assigned Res. Archive"
{
    Caption = 'Project Assigned Resources';
    PageType = List;
    ApplicationArea = Jobs;
    SourceTable = "Job Assigned Resource Archive";
    Editable = false;
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

    procedure SetJobTaskContext(JobTaskArchive: Record "Job Task Archive"): Boolean
    var
        JobAssignedResourceArchive: Record "Job Assigned Resource Archive";
    begin
        if JobTaskArchive."Job Task Type" <> JobTaskArchive."Job Task Type"::Posting then begin
            Message(AssignOnlyToPostingTaskMsg);
            exit(false);
        end;
        JobAssignedResourceArchive.SetRange("Job No.", JobTaskArchive."Job No.");
        JobAssignedResourceArchive.SetRange("Job Task No.", JobTaskArchive."Job Task No.");
        JobAssignedResourceArchive.SetRange("Version No.", JobTaskArchive."Version No.");
        SetTableView(JobAssignedResourceArchive);
        exit(true);
    end;

    var
        ShowKeyColumns: Boolean;
        AssignOnlyToPostingTaskMsg: Label 'Assigned resources are only available for posting-type project tasks.';
}
