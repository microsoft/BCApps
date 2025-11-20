// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Job;

page 9154 "My Jobs"
{
    Caption = 'My Projects';
    PageType = ListPart;
    SourceTable = "My Job";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Job No."; Rec."Job No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the project numbers that are displayed in the My Project Cue on the Role Center.';

                    trigger OnValidate()
                    begin
                        GetJob();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Jobs;
                    Enabled = false;
                    ToolTip = 'Specifies a description of the project.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Jobs;
                    Editable = false;
                    ToolTip = 'Specifies the project''s status.';
                }
                field("Bill-to Name"; Rec."Bill-to Name")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the name of the customer that you send or sent the invoice or credit memo to.';
                }
                field("Percent Completed"; Rec."Percent Completed")
                {
                    ApplicationArea = Jobs;
                    Editable = false;
                    ToolTip = 'Specifies the completion rate of the project.';
                }
                field("Percent Invoiced"; Rec."Percent Invoiced")
                {
                    ApplicationArea = Jobs;
                    Editable = false;
                    ToolTip = 'Specifies how much of the project has been invoiced.';
                }
                field("Exclude from Business Chart"; Rec."Exclude from Business Chart")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies if this project should appear in the business charts for this role center.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Open)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Open';
                Image = ViewDetails;
                RunObject = Page "Job Card";
                RunPageLink = "No." = field("Job No.");
                RunPageMode = View;
                ShortCutKey = 'Return';
                ToolTip = 'Open the card for the selected record.';
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        GetJob();
    end;

    trigger OnOpenPage()
    begin
        Rec.SetRange("User ID", UserId());
    end;

    local procedure GetJob()
    var
        Job: Record Job;
    begin
        if Job.Get(Rec."Job No.") then begin
            Rec.Description := Job.Description;
            Rec.Status := Job.Status;
            Rec."Bill-to Name" := Job."Bill-to Name";
            Rec."Percent Completed" := Job.PercentCompleted();
            Rec."Percent Invoiced" := Job.PercentInvoiced();
        end;

        OnAfterGetJob(Rec);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetJob(var MyJob: Record "My Job")
    begin
    end;
}

