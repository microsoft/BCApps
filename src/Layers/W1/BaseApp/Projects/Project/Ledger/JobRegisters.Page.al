// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Ledger;

using System.Security.User;

page 278 "Job Registers"
{
    AdditionalSearchTerms = 'Job Registers';
    ApplicationArea = Jobs;
    Caption = 'Project Registers';
    Editable = false;
    PageType = List;
    SourceTable = "Job Register";
    SourceTableView = sorting("No.") order(descending);
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Jobs;
                }
                field("Creation Date"; Rec."Creation Date")
                {
                    ApplicationArea = Jobs;
                }
                field("Creation Time"; Rec."Creation Time")
                {
                    ApplicationArea = Jobs;
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = Jobs;

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation(Rec."User ID");
                    end;
                }
                field("Source Code"; Rec."Source Code")
                {
                    ApplicationArea = Jobs;
                }
                field("Journal Batch Name"; Rec."Journal Batch Name")
                {
                    ApplicationArea = Jobs;
                }
                field("From Entry No."; Rec."From Entry No.")
                {
                    ApplicationArea = Jobs;
                }
                field("To Entry No."; Rec."To Entry No.")
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
        area(navigation)
        {
            group("&Register")
            {
                Caption = '&Register';
                Image = Register;
                action("Job Ledger")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Project Ledger';
                    Image = JobLedger;
                    RunObject = Codeunit "Job Reg.-Show Ledger";
                    ToolTip = 'View the project ledger entries.';
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Job Ledger_Promoted"; "Job Ledger")
                {
                }
            }
        }
    }
}

