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
                    ToolTip = 'Specifies a code for the posting group that defines to which G/L account you post project transactions when the project card contains the project posting group.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies a description of project posting groups.';
                }
                field("WIP Costs Account"; Rec."WIP Costs Account")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the work in process (WIP) account for the calculated cost of the project WIP for project tasks with this posting group. The account is normally a balance sheet asset account.';
                }
                field("WIP Accrued Costs Account"; Rec."WIP Accrued Costs Account")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies an account that accumulates postings when the costs recognized, based on the invoiced value of the project, are greater than the current usage total posted If the WIP method for the project is Cost Value or Cost of Sales. The account is normally a balance sheet accrued expense liability account.';
                }
                field("Job Costs Applied Account"; Rec."Job Costs Applied Account")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the balancing account for WIP Cost account for projects. The account is normally an expense (credit) account.';
                }
                field("Item Costs Applied Account"; Rec."Item Costs Applied Account")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the balancing account for the WIP Costs account for items used in projects. The account is normally an expense (credit) account.';
                }
                field("Resource Costs Applied Account"; Rec."Resource Costs Applied Account")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the balancing account for the WIP Costs account for resources used in projects. The account is normally an expense (credit) account.';
                }
                field("G/L Costs Applied Account"; Rec."G/L Costs Applied Account")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the balancing account for the WIP Costs account.';
                }
                field("Job Costs Adjustment Account"; Rec."Job Costs Adjustment Account")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the balancing account to WIP Accrued Costs account if the work in process (WIP) method for the project is Cost Value or Cost of Sales. The account is normally an expense account.';
                }
                field("G/L Expense Acc. (Contract)"; Rec."G/L Expense Acc. (Contract)")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the sales account to be used for general ledger expenses in project tasks with this posting group. If left empty, the G/L account entered on the planning line will be used.';
                }
                field("WIP Accrued Sales Account"; Rec."WIP Accrued Sales Account")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies an account that will be posted to when the revenue that can be recognized for the project is greater than the current invoiced value for the project if the work in process (WIP) method for the project is Sales Value.';
                }
                field("WIP Invoiced Sales Account"; Rec."WIP Invoiced Sales Account")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the account for the invoiced value, for the project for project tasks, with this posting group. The account is normally a Balance sheet liability account.';
                }
                field("Job Sales Applied Account"; Rec."Job Sales Applied Account")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the balancing account to WIP Invoiced Sales Account. The account is normally a contra (or debit) income account.';
                }
                field("Job Sales Adjustment Account"; Rec."Job Sales Adjustment Account")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the balancing account to the WIP Accrued Sales account if the work in process (WIP) Method for the project is the Sales Value. The account is normally an income account.';
                }
                field("Recognized Costs Account"; Rec."Recognized Costs Account")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the account for recognized costs for the project. The account is normally an expense account.';
                }
                field("Recognized Sales Account"; Rec."Recognized Sales Account")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the account for recognized sales (or revenue) for the project. The account is normally an income account.';
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

