// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

using Microsoft.Inventory.Ledger;

page 5808 "Cost Adjustment Logs"
{
    PageType = List;
    ApplicationArea = Basic, Suite;
    SourceTable = "Cost Adjustment Log";
    Caption = 'Cost Adjustment Log';
    SourceTableView = sorting("Entry No.") order(descending);
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Runs)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    Caption = 'Entry No.';
                    ToolTip = 'Specifies the number of the entry.';
                }
                field("Cost Adjustment Run Guid"; Rec."Cost Adjustment Run Guid")
                {
                    Caption = 'Cost Adjustment Run Guid';
                    ToolTip = 'Specifies the unique identifier of the cost adjustment run.';
                    Visible = false;
                }
                field("Item Filter"; Rec."Item Filter")
                {
                    Caption = 'Item Filter';
                    ToolTip = 'Specifies the item filter used for the cost adjustment run.';
                }
                field(Status; Rec.Status)
                {
                    Caption = 'Status';
                    ToolTip = 'Specifies the status of the cost adjustment run.';
                    StyleExpr = StatusStyleExpr;
                }
                field("Starting Date-Time"; Rec."Starting Date-Time")
                {
                    Caption = 'Starting Date-Time';
                    ToolTip = 'Specifies the starting date and time of the cost adjustment run.';
                }
                field("Ending Date-Time"; Rec."Ending Date-Time")
                {
                    Caption = 'Ending Date-Time';
                    ToolTip = 'Specifies the ending date and time of the cost adjustment run.';
                }
                field(Duration; Rec."Ending Date-Time" - Rec."Starting Date-Time")
                {
                    Caption = 'Duration';
                    ToolTip = 'Specifies the duration of the cost adjustment run.';
                }
                field("Item Register No."; Rec."Item Register No.")
                {
                    Caption = 'Item Register No.';
                    ToolTip = 'Specifies the item register number that is created for the cost adjustment run. Blank value indicates that the cost adjustment has not produced any new value entries.';
                }
                field("New Value Entries"; ValueEntriesCreated)
                {
                    Caption = 'New Value Entries';
                    ToolTip = 'Specifies the number of new value entries that are created for the cost adjustment run. Blank value indicates that the cost adjustment has not produced any new value entries.';
                    BlankZero = true;
                }
                field("Adjusted Cost Amount"; AdjustedCostAmount)
                {
                    Caption = 'Adjusted Cost Amount';
                    ToolTip = 'Specifies the adjusted cost amount for the cost adjustment run. Blank value indicates that the cost adjustment has not produced any new value entries.';
                    BlankZero = true;
                }
                field("Last Error"; Rec."Last Error")
                {
                    Caption = 'Last Error';
                    ToolTip = 'Specifies the last error that occurred during the cost adjustment run.';
                }
                field("Last Error Call Stack"; Rec."Last Error Call Stack")
                {
                    Caption = 'Last Error Call Stack';
                    ToolTip = 'Specifies the last error call stack that occurred during the cost adjustment run.';
                }
                field("Failed Item No."; Rec."Failed Item No.")
                {
                    Caption = 'Failed Item No.';
                    ToolTip = 'Specifies the item number that failed during the cost adjustment run.';
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action("Value Entries")
            {
                Caption = 'Value Entries';
                ToolTip = 'Open the Value Entries page to view the value entries that the cost adjustment has produced.';
                Image = ValueLedger;

                trigger OnAction()
                var
                    ItemRegister: Record "Item Register";
                    ValueEntry: Record "Value Entry";
                begin
                    ItemRegister.SetLoadFields("From Value Entry No.", "To Value Entry No.");
                    if not ItemRegister.Get(Rec."Item Register No.") then
                        exit;

                    ValueEntry.SetRange("Entry No.", ItemRegister."From Value Entry No.", ItemRegister."To Value Entry No.");
                    ValueEntry.SetFilter("Item Register No.", '0|%1', Rec."Item Register No.");
                    Page.RunModal(0, ValueEntry);
                end;
            }
        }
        area(Promoted)
        {
            actionref("Value Entries_Promoted"; "Value Entries") { }
        }
    }

    var
        StatusStyleExpr: Text;
        ValueEntriesCreated: Integer;
        AdjustedCostAmount: Decimal;

    trigger OnAfterGetRecord()
    var
        ItemRegister: Record "Item Register";
        ValueEntry: Record "Value Entry";
    begin
        ValueEntriesCreated := 0;
        AdjustedCostAmount := 0;
        if Rec."Item Register No." <> 0 then begin
            ItemRegister.SetLoadFields("From Value Entry No.", "To Value Entry No.");
            ItemRegister.Get(Rec."Item Register No.");
            ValueEntry.SetRange("Entry No.", ItemRegister."From Value Entry No.", ItemRegister."To Value Entry No.");
            ValueEntry.SetFilter("Item Register No.", '0|%1', Rec."Item Register No.");
            ValueEntry.CalcSums("Cost Amount (Actual)");
            AdjustedCostAmount := ValueEntry."Cost Amount (Actual)";
            ValueEntriesCreated := ValueEntry.Count();
        end;

        case Rec.Status of
            Rec.Status::Success:
                StatusStyleExpr := 'Favorable';
            Rec.Status::Failed, Rec.Status::"Timed out":
                StatusStyleExpr := 'Unfavorable';
            else
                StatusStyleExpr := 'Standard';
        end;
    end;
}
