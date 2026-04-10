// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CostAccounting.Budget;

using Microsoft.CostAccounting.Account;
using System.Text;

page 1116 "Cost Budget Names"
{
    ApplicationArea = CostAccounting;
    Caption = 'Cost Budgets';
    PageType = List;
    SourceTable = "Cost Budget Name";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control11)
            {
                ShowCaption = false;
                field(Name; Rec.Name)
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the name of the cost budget.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies a description of the cost budget.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Cost Budget per Period")
            {
                ApplicationArea = CostAccounting;
                Caption = 'Cost Budget per Period';
                Image = LedgerBudget;
                RunObject = Page "Cost Budget per Period";
                RunPageLink = "Budget Filter" = field(Name);
                ShortCutKey = 'Return';
                ToolTip = 'View a summary of the amount budgeted for each cost type in different time periods.';
            }
            action("Cost Budget by Cost Center")
            {
                ApplicationArea = CostAccounting;
                Caption = 'Cost Budget by Cost Center';
                Image = LedgerBudget;
                RunObject = Page "Cost Budget by Cost Center";
                RunPageLink = "Budget Filter" = field(Name);
                ToolTip = 'View a summary of the amount budgeted for each cost center in different time periods.';
            }
            action("Cost Budget by Cost Object")
            {
                ApplicationArea = CostAccounting;
                Caption = 'Cost Budget by Cost Object';
                Image = LedgerBudget;
                RunObject = Page "Cost Budget by Cost Object";
                RunPageLink = "Budget Filter" = field(Name);
                ToolTip = 'View a summary of the amount budgeted for each cost object in different time periods.';
            }
            action("Cost Budget/Movement")
            {
                ApplicationArea = CostAccounting;
                Caption = 'Cost Budget/Movement';
                Image = LedgerBudget;
                RunObject = Page "Cost Type Balance/Budget";
                RunPageLink = "Budget Filter" = field(Name);
                ToolTip = 'View a summary of the net changes and the budgeted amounts for different time periods for the cost type that you select in the chart of cost types.';
            }
            group(Functions)
            {
                Caption = 'Functions';
                Image = "Action";
                action("Transfer Budget to Actual")
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'Transfer Budget to Actual';
                    Image = CopyCostBudgettoCOA;
                    RunObject = Report "Transfer Budget to Actual";
                    ToolTip = 'Transfer the budgeted costs to the actual costs of cost centers or cost objects. At the beginning of the year, some companies establish a cost budget and then transfer these budgeted costs to cost centers or cost objects. The budget entries can be transferred to a cost journal and posted as actual costs in the journal.';
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Cost Budget per Period_Promoted"; "Cost Budget per Period")
                {
                }
                actionref("Cost Budget by Cost Center_Promoted"; "Cost Budget by Cost Center")
                {
                }
                actionref("Cost Budget by Cost Object_Promoted"; "Cost Budget by Cost Object")
                {
                }
                actionref("Cost Budget/Movement_Promoted"; "Cost Budget/Movement")
                {
                }
            }
        }
    }

    procedure GetSelectionFilter(): Text
    var
        CostBudgetName: Record "Cost Budget Name";
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
    begin
        CurrPage.SetSelectionFilter(CostBudgetName);
        exit(SelectionFilterManagement.GetSelectionFilterForCostBudgetName(CostBudgetName));
    end;
}

