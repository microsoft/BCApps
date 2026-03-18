// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CostAccounting.Allocation;

using Microsoft.CostAccounting.Ledger;
using Microsoft.CostAccounting.Reports;
using System.Security.User;

page 1105 "Cost Allocation"
{
    Caption = 'Cost Allocation';
    PageType = Document;
    SourceTable = "Cost Allocation Source";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(ID; Rec.ID)
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the ID that applies to the cost allocation.';
                }
                field(Level; Rec.Level)
                {
                    ApplicationArea = CostAccounting;
                    Importance = Promoted;
                    ToolTip = 'Specifies by which level the cost allocation posting is done. For example, this makes sure that costs are allocated at level 1 from the ADM cost center to the WORKSHOP and PROD cost centers, before they are allocated at level 2 from the PROD cost center to the FURNITURE, CHAIRS, and PAINT cost objects.';
                }
                field("Valid From"; Rec."Valid From")
                {
                    ApplicationArea = CostAccounting;
                    Importance = Promoted;
                    ToolTip = 'Specifies the date when the cost allocation starts.';
                }
                field("Valid To"; Rec."Valid To")
                {
                    ApplicationArea = CostAccounting;
                    Importance = Promoted;
                    ToolTip = 'Specifies the date that the cost allocation ends.';
                }
                field(Variant; Rec.Variant)
                {
                    ApplicationArea = CostAccounting;
                    Importance = Promoted;
                    ToolTip = 'Specifies the variant of the cost allocation.';
                }
                field("Cost Type Range"; Rec."Cost Type Range")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies a cost type range to define which cost types are allocated. If all costs that are incurred by the cost center are allocated, you do not have to set a cost type range.';
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
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies that the related record is blocked from being posted in transactions, for example a customer that is declared insolvent or an item that is placed in quarantine.';
                }
            }
            part(AllocTarget; "Cost Allocation Target")
            {
                ApplicationArea = CostAccounting;
                SubPageLink = ID = field(ID);
            }
            group(Statistics)
            {
                Caption = 'Statistics';
                field("Allocation Source Type"; Rec."Allocation Source Type")
                {
                    ApplicationArea = CostAccounting;
                    Importance = Promoted;
                    ToolTip = 'Specifies if the allocation comes from both budgeted and actual costs, only budgeted costs, or only actual costs.';
                }
                field("Last Date Modified"; Rec."Last Date Modified")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies when the cost allocation was last modified.';
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation(Rec."User ID");
                    end;
                }
                field(Comment; Rec.Comment)
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies a comment that applies to the cost allocation.';
                }
                field("Total Share"; Rec."Total Share")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the sum of the shares allocated.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("Allo&cation")
            {
                Caption = 'Allo&cation';
                Image = Allocate;
                separator(Action3)
                {
                }
                action("Cost E&ntries")
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'Cost E&ntries';
                    Image = CostEntries;
                    RunObject = Page "Cost Entries";
                    RunPageLink = "Allocation ID" = field(ID);
                    RunPageView = sorting("Allocation ID", "Posting Date");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View cost entries, which can come from sources such as automatic transfer of general ledger entries to cost entries, manual posting for pure cost entries, internal charges, and manual allocations, and automatic allocation postings for actual costs.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Calculate Allocation Key")
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'Calculate Allocation Key';
                    Image = CalculateCost;
                    ToolTip = 'Recalculate the dynamic shares of the allocation key.';

                    trigger OnAction()
                    var
                        CostAccAllocation: Codeunit "Cost Account Allocation";
                    begin
                        CostAccAllocation.CalcAllocationKey(Rec);
                    end;
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
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Calculate Allocation Key_Promoted"; "Calculate Allocation Key")
                {
                }
            }
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

