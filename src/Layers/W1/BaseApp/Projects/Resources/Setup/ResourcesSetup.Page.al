// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Resources.Setup;

using Microsoft.Projects.Resources.Resource;

page 462 "Resources Setup"
{
    AccessByPermission = TableData Resource = R;
    ApplicationArea = Jobs;
    Caption = 'Resources Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "Resources Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group("Time Sheets")
            {
                Caption = 'Time Sheets';

                field("Time Sheet First Weekday"; Rec."Time Sheet First Weekday")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the first weekday to use on a time sheet. The default is Monday.';
                }
                field("Time Sheet by Job Approval"; Rec."Time Sheet by Job Approval")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies whether time sheets must be approved on a per job basis by the user specified for the job.';
                }
                field("Time Sheet Submission Policy"; Rec."Time Sheet Submission Policy")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the policy for submitting time sheets.';
                }
                field("Incl. Time Sheet Date in Jnl."; Rec."Incl. Time Sheet Date in Jnl.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies whether the date of the time sheets entry is included in the description in project journal line.';
                }
            }
            group(Numbering)
            {
                Caption = 'Numbering';
                field("Resource Nos."; Rec."Resource Nos.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number series code you can use to assign numbers to resources.';
                }
                field("Time Sheet Nos."; Rec."Time Sheet Nos.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number series code you can use to assign document numbers to time sheets.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;
}

