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
                }
                field("Time Sheet by Job Approval"; Rec."Time Sheet by Job Approval")
                {
                    ApplicationArea = Jobs;
                }
                field("Time Sheet Submission Policy"; Rec."Time Sheet Submission Policy")
                {
                    ApplicationArea = Jobs;
                }
                field("Incl. Time Sheet Date in Jnl."; Rec."Incl. Time Sheet Date in Jnl.")
                {
                    ApplicationArea = Jobs;
                }
            }
            group(Numbering)
            {
                Caption = 'Numbering';
                field("Resource Nos."; Rec."Resource Nos.")
                {
                    ApplicationArea = Jobs;
                }
                field("Time Sheet Nos."; Rec."Time Sheet Nos.")
                {
                    ApplicationArea = Jobs;
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

