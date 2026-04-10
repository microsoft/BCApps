// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CostAccounting.Budget;

using System.Security.User;

page 1121 "Cost Budget Registers"
{
    ApplicationArea = CostAccounting;
    Caption = 'Cost Budget Registers';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "Cost Budget Register";
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(Control8)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = CostAccounting;
                    Editable = false;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Source; Rec.Source)
                {
                    ApplicationArea = CostAccounting;
                    Editable = false;
                    ToolTip = 'Specifies the source for the cost budget register.';
                }
                field(Level; Rec.Level)
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies by which level the cost allocation posting is done. For example, this makes sure that costs are allocated at level 1 from the ADM cost center to the WORKSHOP and PROD cost centers, before they are allocated at level 2 from the PROD cost center to the FURNITURE, CHAIRS, and PAINT cost objects.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the entry''s posting date.';
                }
                field("From Cost Budget Entry No."; Rec."From Cost Budget Entry No.")
                {
                    ApplicationArea = CostAccounting;
                    Editable = false;
                    ToolTip = 'Specifies the first general ledger budget entry number in the register if the cost budget posting is transferred from the general ledger budget.';
                }
                field("To Cost Budget Entry No."; Rec."To Cost Budget Entry No.")
                {
                    ApplicationArea = CostAccounting;
                    Editable = false;
                    ToolTip = 'Specifies the last cost budget entry number to be used in the line.';
                }
                field("No. of Entries"; Rec."No. of Entries")
                {
                    ApplicationArea = CostAccounting;
                    Editable = false;
                    ToolTip = 'Specifies the number of entries in the cost budget register.';
                }
                field("From Budget Entry No."; Rec."From Budget Entry No.")
                {
                    ApplicationArea = CostAccounting;
                    Editable = false;
                    ToolTip = 'Specifies the first general ledger budget entry number in the register if the budget posting is transferred from the general ledger budget.';
                }
                field("To Budget Entry No."; Rec."To Budget Entry No.")
                {
                    ApplicationArea = CostAccounting;
                    Editable = false;
                    ToolTip = 'Specifies the last budget entry number to be used in the line.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = CostAccounting;
                    Editable = false;
                    ToolTip = 'Specifies the amount of the transferred and allocated cost budget entries.';
                }
                field(Closed; Rec.Closed)
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies whether the cost has been closed.';
                }
                field("Processed Date"; Rec."Processed Date")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies when the cost budget register was last updated.';
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
                field("Journal Batch Name"; Rec."Journal Batch Name")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the name of the journal batch, a personalized journal layout, that the entries were posted from.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Entry")
            {
                Caption = '&Entry';
                Image = Entry;
                action("&Cost Budget Entries")
                {
                    ApplicationArea = CostAccounting;
                    Caption = '&Cost Budget Entries';
                    Image = GLRegisters;
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the related cost budget entries.';

                    trigger OnAction()
                    var
                        CostBudgetEntry: Record "Cost Budget Entry";
                        CostBudgetEntries: Page "Cost Budget Entries";
                    begin
                        CostBudgetEntry.SetRange("Entry No.", Rec."From Cost Budget Entry No.", Rec."To Cost Budget Entry No.");
                        CostBudgetEntries.SetTableView(CostBudgetEntry);
                        CostBudgetEntries.Editable := false;
                        CostBudgetEntries.Run();
                    end;
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("&Delete Cost Budget Entries")
                {
                    ApplicationArea = CostAccounting;
                    Caption = '&Delete Cost Budget Entries';
                    Image = Delete;
                    RunObject = Report "Delete Cost Budget Entries";
                    RunPageOnRec = true;
                    ToolTip = 'Delete posted cost budget entries and reverses allocations, for example when you simulate budget allocations by using different allocation codes, when you reverse cost budget allocations to include late entries in a combined entry as part of the same posting process, or when you cancel a cost budget entry in the register.';
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("&Cost Budget Entries_Promoted"; "&Cost Budget Entries")
                {
                }
            }
        }
    }
}

