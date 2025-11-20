// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

using Microsoft.Inventory.Ledger;

page 5809 "Cost Adjustment Detailed Logs"
{
    PageType = List;
    ApplicationArea = Basic, Suite;
    SourceTable = "Cost Adjustment Detailed Log";
    Caption = 'Cost Adjustment Log per Item';
    SourceTableView = sorting("Item No.", "Ending Date-Time") order(descending);
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field("Cost Adjustment Run Guid"; Rec."Cost Adjustment Run Guid")
                {
                    Caption = 'Cost Adjustment Run Guid';
                    ToolTip = 'Specifies the unique identifier of the cost adjustment run.';
                    Visible = false;
                }
                field("Item No."; Rec."Item No.")
                {
                    Caption = 'Item No.';
                    ToolTip = 'Specifies the item number.';
                }
                field("Run Status"; Status)
                {
                    Caption = 'Status';
                    ToolTip = 'Specifies the status of the cost adjustment run.';
                    StyleExpr = StatusStyleExpr;
                }
                field("Starting Date-Time"; Rec."Starting Date-Time")
                {
                    Caption = 'Starting Date-Time';
                    ToolTip = 'Specifies the starting date and time of the cost adjustment run for the item.';
                }
                field("Ending Date-Time"; Rec."Ending Date-Time")
                {
                    Caption = 'Ending Date-Time';
                    ToolTip = 'Specifies the ending date and time of the cost adjustment run for the item.';
                }
                field(Duration; Rec.Duration)
                {
                    Caption = 'Duration';
                    ToolTip = 'Specifies the duration of the cost adjustment run for the item.';
                }
                field("Item Register No."; ItemRegisterNo)
                {
                    Caption = 'Item Register No.';
                    ToolTip = 'Specifies the item register number that is created for the item. Blank value indicates that the cost adjustment has not produced any new value entries.';
                    TableRelation = "Item Register";
                    BlankZero = true;
                }
                field("New Value Entries"; ValueEntriesCreated)
                {
                    Caption = 'New Value Entries';
                    ToolTip = 'Specifies the number of new value entries that are created for the item. Blank value indicates that the cost adjustment has not produced any new value entries.';
                    BlankZero = true;
                }
                field("Adjusted Cost Amount"; AdjustedCostAmount)
                {
                    Caption = 'Adjusted Cost Amount';
                    ToolTip = 'Specifies the adjusted cost amount for the item. Blank value indicates that the cost adjustment has not produced any new value entries.';
                    BlankZero = true;
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
                ToolTip = 'Open the Value Entries page to view the value entries that the the cost adjustment has produced for the item.';
                Image = ValueLedger;

                trigger OnAction()
                var
                    ItemRegister: Record "Item Register";
                    ValueEntry: Record "Value Entry";
                begin
                    ItemRegister.SetLoadFields("From Value Entry No.", "To Value Entry No.");
                    if not ItemRegister.Get(ItemRegisterNo) then
                        exit;

                    ValueEntry.SetRange("Entry No.", ItemRegister."From Value Entry No.", ItemRegister."To Value Entry No.");
                    ValueEntry.SetFilter("Item Register No.", '0|%1', ItemRegisterNo);
                    ValueEntry.SetRange("Item No.", Rec."Item No.");
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
        Status: Enum "Cost Adjustment Run Status";
        StatusStyleExpr: Text;
        ItemRegisterNo: Integer;
        ValueEntriesCreated: Integer;
        AdjustedCostAmount: Decimal;

    trigger OnAfterGetRecord()
    var
        CostAdjustmentLog: Record "Cost Adjustment Log";
        ItemRegister: Record "Item Register";
        ValueEntry: Record "Value Entry";
    begin
        CostAdjustmentLog.SetCurrentKey("Cost Adjustment Run Guid");
        CostAdjustmentLog.SetRange("Cost Adjustment Run Guid", Rec."Cost Adjustment Run Guid");
        CostAdjustmentLog.FindFirst();
        Status := CostAdjustmentLog.Status;
        ItemRegisterNo := CostAdjustmentLog."Item Register No.";

        ValueEntriesCreated := 0;
        AdjustedCostAmount := 0;
        if ItemRegisterNo <> 0 then begin
            ItemRegister.SetLoadFields("From Value Entry No.", "To Value Entry No.");
            ItemRegister.Get(ItemRegisterNo);
            ValueEntry.SetRange("Entry No.", ItemRegister."From Value Entry No.", ItemRegister."To Value Entry No.");
            ValueEntry.SetFilter("Item Register No.", '0|%1', ItemRegisterNo);
            ValueEntry.SetRange("Item No.", Rec."Item No.");
            ValueEntry.CalcSums("Cost Amount (Actual)");
            AdjustedCostAmount := ValueEntry."Cost Amount (Actual)";
            ValueEntriesCreated := ValueEntry.Count();
        end;

        case Status of
            Status::Success:
                StatusStyleExpr := 'Favorable';
            Status::Failed, Status::"Timed out":
                StatusStyleExpr := 'Unfavorable';
            else
                StatusStyleExpr := 'Standard';
        end;
    end;
}
