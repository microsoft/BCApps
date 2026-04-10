// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Job;

page 211 "Job Posting Groups"
{
    AdditionalSearchTerms = 'Job Posting Groups';
    ApplicationArea = Jobs;
    Caption = 'Project Posting Groups';
    PageType = List;
    SourceTable = "Job Posting Group";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Jobs;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Jobs;
                }
                field("WIP Costs Account"; Rec."WIP Costs Account")
                {
                    ApplicationArea = Jobs;
                }
                field("WIP Accrued Costs Account"; Rec."WIP Accrued Costs Account")
                {
                    ApplicationArea = Jobs;
                }
                field("Job Costs Applied Account"; Rec."Job Costs Applied Account")
                {
                    ApplicationArea = Jobs;
                }
                field("Item Costs Applied Account"; Rec."Item Costs Applied Account")
                {
                    ApplicationArea = Jobs;
                }
                field("Resource Costs Applied Account"; Rec."Resource Costs Applied Account")
                {
                    ApplicationArea = Jobs;
                }
                field("G/L Costs Applied Account"; Rec."G/L Costs Applied Account")
                {
                    ApplicationArea = Jobs;
                }
                field("Job Costs Adjustment Account"; Rec."Job Costs Adjustment Account")
                {
                    ApplicationArea = Jobs;
                }
                field("G/L Expense Acc. (Contract)"; Rec."G/L Expense Acc. (Contract)")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the sales account to be used for general ledger expenses in project tasks with this posting group. If left empty, the G/L account entered on the planning line will be used.';
                }
                field("WIP Accrued Sales Account"; Rec."WIP Accrued Sales Account")
                {
                    ApplicationArea = Jobs;
                }
                field("WIP Invoiced Sales Account"; Rec."WIP Invoiced Sales Account")
                {
                    ApplicationArea = Jobs;
                }
                field("Job Sales Applied Account"; Rec."Job Sales Applied Account")
                {
                    ApplicationArea = Jobs;
                }
                field("Job Sales Adjustment Account"; Rec."Job Sales Adjustment Account")
                {
                    ApplicationArea = Jobs;
                }
                field("Recognized Costs Account"; Rec."Recognized Costs Account")
                {
                    ApplicationArea = Jobs;
                }
                field("Recognized Sales Account"; Rec."Recognized Sales Account")
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
}

