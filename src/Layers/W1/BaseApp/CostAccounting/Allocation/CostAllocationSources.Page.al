// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CostAccounting.Allocation;

using Microsoft.CostAccounting.Account;
using Microsoft.CostAccounting.Reports;

page 1102 "Cost Allocation Sources"
{
    ApplicationArea = CostAccounting;
    Caption = 'Cost Allocations';
    CardPageID = "Cost Allocation";
    Editable = false;
    PageType = List;
    SourceTable = "Cost Allocation Source";
    SourceTableView = sorting(Level, "Valid From", "Valid To", "Cost Type Range");
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control8)
            {
                ShowCaption = false;
                field(ID; Rec.ID)
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the user ID that applies to the cost allocation.';
                }
                field(Level; Rec.Level)
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies by which level the cost allocation posting is done. For example, this makes sure that costs are allocated at level 1 from the ADM cost center to the WORKSHOP and PROD cost centers, before they are allocated at level 2 from the PROD cost center to the FURNITURE, CHAIRS, and PAINT cost objects.';
                }
                field(Variant; Rec.Variant)
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the variant of the cost allocation sources.';
                }
                field("Valid From"; Rec."Valid From")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the date that the cost allocation source starts.';
                }
                field("Valid To"; Rec."Valid To")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the date that the cost allocation source ends.';
                }
                field("Cost Type Range"; Rec."Cost Type Range")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies a cost type range to define which cost types are allocated. If all costs that are incurred by the cost center are allocated, you do not have to set a cost type range.';
                    Visible = false;
                }
                field("Cost Center Code"; Rec."Cost Center Code")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the cost center code. The code serves as a default value for cost posting that is captured later in the cost journal.';
                }
                field("Cost Object Code"; Rec."Cost Object Code")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the cost object code. The code serves as a default value for cost posting that is captured later in the cost journal.';
                }
                field("Credit to Cost Type"; Rec."Credit to Cost Type")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the cost type to which the credit posting is posted. The costs that are allocated are credited to the source cost center. It is useful to set up a helping cost type to later identify the allocation postings in the statistics and reports.';
                }
                field("Total Share"; Rec."Total Share")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the sum of the shares of the cost allocation targets.';
                    Visible = false;
                }
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies that the related record is blocked from being posted in transactions, for example a customer that is declared insolvent or an item that is placed in quarantine.';
                    Visible = false;
                }
                field("Allocation Source Type"; Rec."Allocation Source Type")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies if the allocation comes from both budgeted and actual costs, only budgeted costs, or only actual costs.';
                    Visible = false;
                }
                field(Comment; Rec.Comment)
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies a comment that applies to the cost allocation.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Allocation")
            {
                Caption = '&Allocation';
                Image = Allocate;
                action("&Allocation Target")
                {
                    ApplicationArea = CostAccounting;
                    Caption = '&Allocation Target';
                    Image = Setup;
                    RunObject = Page "Cost Allocation Target List";
                    RunPageLink = ID = field(ID);
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'Specifies the cost allocation target entries.';
                }
                action(PageChartOfCostTypes)
                {
                    ApplicationArea = CostAccounting;
                    Caption = '&Corresponding Cost Types';
                    Image = CompareCost;
                    RunObject = Page "Chart of Cost Types";
                    RunPageLink = "No." = field(filter("Cost Type Range"));
                    ToolTip = 'View the related G/L accounts in the Chart of Cost Types window.';
                }
            }
        }
        area(reporting)
        {
            action(Allocations)
            {
                ApplicationArea = CostAccounting;
                Caption = 'Allocations';
                Image = Allocations;
                RunObject = Report "Cost Allocations";
                ToolTip = 'Verify and print the allocation source and targets that are defined in the Cost Allocation window for controlling purposes.';
            }
        }
        area(processing)
        {
            group("&Functions")
            {
                Caption = '&Functions';
                Image = "Action";
                action("&Allocate Costs")
                {
                    ApplicationArea = CostAccounting;
                    Caption = '&Allocate Costs';
                    Enabled = true;
                    Image = Costs;
                    RunObject = Report "Cost Allocation";
                    ToolTip = 'Specifies the cost allocation options.';
                }
                action("&Calculate Allocation Keys")
                {
                    ApplicationArea = CostAccounting;
                    Caption = '&Calculate Allocation Keys';
                    Image = Calculate;
                    RunObject = Codeunit "Cost Account Allocation";
                    ToolTip = 'Recalculate the dynamic shares of all allocation keys.';
                }
            }
        }
        area(Promoted)
        {
            group(Category_Report)
            {
                Caption = 'Reports';

                actionref(Allocations_Promoted; Allocations)
                {
                }
            }
        }
    }
}

