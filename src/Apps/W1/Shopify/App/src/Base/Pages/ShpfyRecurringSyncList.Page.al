// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

using System.Threading;

page 30178 "Shpfy Recurring Sync List"
{
    Caption = 'Recurring Shopify Synchronizations';
    PageType = List;
    SourceTable = "Job Queue Entry";
    SourceTableTemporary = true;
    CardPageId = "Job Queue Entry Card";
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Schedules)
            {
                field(Synchronization; TempShpfyRecurringSyncBuffer.Synchronization)
                {
                    ToolTip = 'Specifies the synchronization workload and direction.';
                }
                field(Shop; TempShpfyRecurringSyncBuffer."Shop Display")
                {
                    ToolTip = 'Specifies the shop or shops covered by this schedule.';
                }
                field(Frequency; Rec."No. of Minutes between Runs")
                {
                    ToolTip = 'Specifies how often the synchronization runs, in minutes.';
                }
                field(StartingTime; Rec."Starting Time")
                {
                    ToolTip = 'Specifies the time when the schedule starts.';
                }
                field(NextRunDateTime; Rec."Earliest Start Date/Time")
                {
                    Caption = 'Next Run Date/Time';
                    ToolTip = 'Specifies the earliest date and time when the recurring job can start.';
                }
                field(Status; TempShpfyRecurringSyncBuffer."Job Queue Status")
                {
                    Caption = 'Status';
                    ToolTip = 'Specifies the current status of the recurring job queue entry.';
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies the description of the recurring job queue entry.';
                }
                field(UserID; Rec."User ID")
                {
                    ToolTip = 'Specifies the user who created the recurring job queue entry.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(OpenSchedule)
            {
                Caption = 'Open schedule';
                Image = Edit;
                ToolTip = 'Open the Job Queue Entry Card to view or edit this recurring schedule.';

                trigger OnAction()
                begin
                    OpenJobQueueEntry();
                end;
            }
        }
        area(Promoted)
        {
            actionref(OpenSchedule_Promoted; OpenSchedule) { }
        }
    }

    var
        TempShpfyRecurringSyncBuffer: Record "Shpfy Recurring Sync Buffer" temporary;

    trigger OnAfterGetRecord()
    var
        ScheduleInfoNotFoundErr: Label 'The recurring schedule information could not be loaded.';
    begin
        TempShpfyRecurringSyncBuffer.Reset();
        TempShpfyRecurringSyncBuffer.SetRange("Job Queue Entry ID", Rec.ID);
        if not TempShpfyRecurringSyncBuffer.FindFirst() then
            Error(ScheduleInfoNotFoundErr);
    end;

    internal procedure SetShop(ShopToSet: Record "Shpfy Shop")
    var
        ShpfyRecurringScheduleMgt: Codeunit "Shpfy Recurring Schedule Mgt.";
    begin
        ShpfyRecurringScheduleMgt.BuildExistingScheduleEntries(ShopToSet, Rec, TempShpfyRecurringSyncBuffer);
    end;

    local procedure OpenJobQueueEntry()
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueEntryNoLongerExistsErr: Label 'The recurring job queue entry no longer exists.';
    begin
        if not JobQueueEntry.Get(Rec.ID) then
            Error(JobQueueEntryNoLongerExistsErr);
        Page.RunModal(Page::"Job Queue Entry Card", JobQueueEntry);
    end;
}
