// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.WIP;

page 1028 "Job WIP Totals"
{
    Caption = 'Project WIP Totals';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = ListPart;
    SourceTable = "Job WIP Total";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Job Task No."; Rec."Job Task No.")
                {
                    ApplicationArea = Jobs;
                }
                field("WIP Method"; Rec."WIP Method")
                {
                    ApplicationArea = Jobs;
                }
                field("WIP Posting Date"; Rec."WIP Posting Date")
                {
                    ApplicationArea = Jobs;
                }
                field("WIP Warnings"; Rec."WIP Warnings")
                {
                    ApplicationArea = Jobs;
                }
                field("Schedule (Total Cost)"; Rec."Schedule (Total Cost)")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the total of the budgeted costs for the project.';
                }
                field("Schedule (Total Price)"; Rec."Schedule (Total Price)")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the total of the budgeted prices for the project.';
                }
                field("Usage (Total Cost)"; Rec."Usage (Total Cost)")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies project usage in relation to total cost up to the date of the last project WIP calculation.';
                }
                field("Usage (Total Price)"; Rec."Usage (Total Price)")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies project usage in relation to total price up to the date of the last project WIP calculation.';
                }
                field("Contract (Total Cost)"; Rec."Contract (Total Cost)")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the value of the billable in relation to total cost up to the date of the last project WIP calculation.';
                }
                field("Contract (Total Price)"; Rec."Contract (Total Price)")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the value of the billable in relation to the total price up to the date of the last project WIP calculation.';
                }
                field("Contract (Invoiced Price)"; Rec."Contract (Invoiced Price)")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the price amount that has been invoiced and posted in relation to the billable for the current WIP calculation.';
                }
                field("Contract (Invoiced Cost)"; Rec."Contract (Invoiced Cost)")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the cost amount that has been invoiced and posted in relation to the billable for the current WIP calculation.';
                }
                field("Calc. Recog. Sales Amount"; Rec."Calc. Recog. Sales Amount")
                {
                    ApplicationArea = Jobs;
                }
                field("Calc. Recog. Costs Amount"; Rec."Calc. Recog. Costs Amount")
                {
                    ApplicationArea = Jobs;
                }
                field("Cost Completion %"; Rec."Cost Completion %")
                {
                    ApplicationArea = Jobs;
                }
                field("Invoiced %"; Rec."Invoiced %")
                {
                    ApplicationArea = Jobs;
                }
            }
        }
    }

    actions
    {
    }
}

