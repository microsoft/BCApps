// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

using Microsoft.Inventory.Setup;
using System.Environment;

page 5811 "Cost Adjustment Runners"
{
    PageType = List;
    ApplicationArea = Basic, Suite;
    SourceTable = "Cost Adj. Item Bucket";
    Caption = 'Cost Adjustment - Item Batches';
    AutoSplitKey = true;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Runs)
            {
                ShowCaption = false;

                field("Line No."; Rec."Line No.")
                {
                    Caption = 'Line No.';
                    Visible = false;
                }
                field("Item Filter"; Rec."Item Filter")
                {
                    Caption = 'Item Filter';
                }
                field("Timeout (Minutes)"; Rec."Timeout (Minutes)")
                {
                    Caption = 'Timeout (Minutes)';
                    ToolTip = 'Specifies the number of minutes that the cost adjustment process is allowed to run before it is canceled.';
                }
                field("Reschedule Count"; Rec."Reschedule Count")
                {
                    Caption = 'Max. Retry Attempts';
                }
                field("Post to G/L"; Rec."Post to G/L")
                {
                    Caption = 'Post to G/L';
                    Editable = AutoPostToGLEnabled;
                }
                field(Trace; Rec.Trace)
                {
                    Caption = 'Trace';
                }
                field(Status; Rec.Status)
                {
                    Caption = 'Status';
                    StyleExpr = StatusStyleExpr;
                    Editable = false;
                }
                field("Starting Date-Time"; Rec."Starting Date-Time")
                {
                    Caption = 'Starting Date-Time';
                    Editable = false;
                }
                field("Ending Date-Time"; Rec."Ending Date-Time")
                {
                    Caption = 'Ending Date-Time';
                    Editable = false;
                }
                field("Last Error"; Rec."Last Error")
                {
                    Caption = 'Last Error';
                    Editable = false;
                }
                field("Last Error Call Stack"; Rec."Last Error Call Stack")
                {
                    Caption = 'Last Error Call Stack';
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Refresh)
            {
                Caption = 'Refresh';
                ToolTip = 'Refresh the information on the page.';
                Image = Refresh;

                trigger OnAction()
                begin
                    CurrPage.Update(false);
                end;
            }
            action("Add Missing Items")
            {
                Caption = 'Add missing items';
                ToolTip = 'Add a new batch for all items that are not yet included in any batch.';
                Image = Add;

                trigger OnAction()
                var
                    CostAdjItemBucket: Record "Cost Adj. Item Bucket";
                begin
                    CostAdjItemBucket.AddMissingItems();
                end;
            }
            action(Run)
            {
                Caption = 'Run';
                ToolTip = 'Run the cost adjustment for all not started item batches.';
                Image = Start;
                Enabled = not IsRunning;

                RunObject = report "Adjust Cost - Item Buckets";
            }
            action(RunForeground)
            {
                Caption = 'Run in Foreground';
                ToolTip = 'Run the cost adjustment for all not started item batches in the foreground.';
                Image = Start;
                Enabled = not IsRunning;

                trigger OnAction()
                var
                    AdjustCostItemBuckets: Report "Adjust Cost - Item Buckets";
                begin
                    AdjustCostItemBuckets.SetRunForeground(true);
                    AdjustCostItemBuckets.Run();
                end;
            }
            action(Stop)
            {
                Caption = 'Stop';
                ToolTip = 'Stop all running cost adjustment tasks.';
                Image = Stop;

                trigger OnAction()
                var
                    CostAdjItemBucket: Record "Cost Adj. Item Bucket";
                begin
                    CancelScheduledTasks();
                    CostAdjItemBucket.CancelBucket(true);
                end;
            }
            action(Cancel)
            {
                Caption = 'Cancel';
                ToolTip = 'Exclude the item batch from the cost adjustment.';
                Image = Cancel;
                Enabled = not IsRunning;

                trigger OnAction()
                var
                    CostAdjItemBucket: Record "Cost Adj. Item Bucket";
                begin
                    CurrPage.SetSelectionFilter(CostAdjItemBucket);
                    CostAdjItemBucket.CancelBucket(true);
                end;
            }
            action(Reset)
            {
                Caption = 'Reset';
                ToolTip = 'Reset the item batch to not started.';
                Image = Reuse;
                Enabled = not IsRunning;

                trigger OnAction()
                var
                    CostAdjItemBucket: Record "Cost Adj. Item Bucket";
                begin
                    CurrPage.SetSelectionFilter(CostAdjItemBucket);
                    CostAdjItemBucket.CancelBucket(false);
                end;
            }
            action("Trace Log")
            {
                Caption = 'Trace Log';
                ToolTip = 'View the trace log for the latest cost adjustment run.';
                Image = Trace;

                RunObject = page "Cost Adjustment Trace Logs";
            }
        }
        area(Promoted)
        {
            actionref("Refresh_Promoted"; Refresh) { }
            actionref("Add Missing Items_Promoted"; "Add Missing Items") { }
            actionref("Run_Promoted"; Run) { }
            actionref("Run Foreground_Promoted"; RunForeground) { }
            actionref("Stop_Promoted"; Stop) { }
            actionref("Cancel_Promoted"; Cancel) { }
            actionref("Reset_Promoted"; Reset) { }
            actionref("Trace Log_Promoted"; "Trace Log") { }
        }
    }

    var
        InventorySetup: Record "Inventory Setup";
        StatusStyleExpr: Text;
        AutoPostToGLEnabled: Boolean;
        IsRunning: Boolean;

    trigger OnOpenPage()
    begin
        InventorySetup.SetLoadFields("Automatic Cost Posting");
        InventorySetup.Get();
        AutoPostToGLEnabled := InventorySetup."Automatic Cost Posting";
    end;

    trigger OnAfterGetRecord()
    begin
        IsRunning := Rec.Status = Rec.Status::Running;

        case Rec.Status of
            Rec.Status::Success:
                StatusStyleExpr := 'Favorable';
            Rec.Status::Failed, Rec.Status::"Timed out":
                StatusStyleExpr := 'Unfavorable';
            else
                StatusStyleExpr := 'Standard';
        end;
    end;

    procedure CancelScheduledTasks()
    var
        ScheduledTask: Record "Scheduled Task";
    begin
        ScheduledTask.SetRange("Run Codeunit", Codeunit::"Cost Adj. Session Scheduler");
        if ScheduledTask.FindSet() then
            repeat
                TaskScheduler.CancelTask(ScheduledTask.ID);
            until ScheduledTask.Next() = 0;
    end;
}
