// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

page 30179 "Shpfy Recurring Sync Selection"
{
    Caption = 'Synchronizations';
    PageType = ListPart;
    SourceTable = "Shpfy Recurring Sync Buffer";
    SourceTableTemporary = true;
    ApplicationArea = All;
    UsageCategory = None;
    Editable = true;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Workloads)
            {
                field(Selected; Rec.Selected)
                {
                    Editable = Rec.Selectable;

                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field(Synchronization; Rec.Synchronization)
                {
                    Editable = false;
                    ToolTip = 'Specifies the synchronization workload and direction. Choose the value to see what the synchronization does.';

                    trigger OnDrillDown()
                    begin
                        Message(Rec.Description);
                    end;
                }
                field(Frequency; Rec.Frequency)
                {
                    Editable = Rec.Selectable;

                    trigger OnValidate()
                    begin
                        if Rec.Frequency <= 0 then
                            Message(ScheduleMgt.GetFrequencyErrorText(Rec));
                        CurrPage.Update(true);
                    end;
                }
                field(Readiness; Rec.Readiness)
                {
                    Editable = false;
                }
                field(Details; Rec.Details)
                {
                    Editable = false;
                    ToolTip = 'Specifies the setup required before this synchronization can be scheduled. Choose the text to open the page where you can complete the setup.';

                    trigger OnDrillDown()
                    begin
                        if ScheduleMgt.OpenSetupTarget(Shop, Rec) then
                            Refresh();
                    end;
                }
            }
        }
    }

    var
        Shop: Record "Shpfy Shop";
        ScheduleMgt: Codeunit "Shpfy Recurring Schedule Mgt.";

    internal procedure Load(ShopToLoad: Record "Shpfy Shop"; var HasSchedules: Boolean)
    begin
        Shop := ShopToLoad;
        ScheduleMgt.BuildRecommendationsWithScheduleState(Shop, Rec, HasSchedules);
        if Rec.FindFirst() then;
        CurrPage.Update(false);
    end;

    internal procedure Refresh(): Boolean
    var
        TempPreviousRecurringSyncBuffer: Record "Shpfy Recurring Sync Buffer" temporary;
        HasSchedules: Boolean;
        CurrentEntryNo: Integer;
    begin
        CurrentEntryNo := Rec."Entry No.";
        Rec.Reset();
        if Rec.FindSet(false) then
            repeat
                TempPreviousRecurringSyncBuffer := Rec;
                TempPreviousRecurringSyncBuffer.Insert(false);
            until Rec.Next() = 0;

        Shop.Get(Shop.Code);
        ScheduleMgt.BuildRecommendationsWithScheduleState(Shop, Rec, HasSchedules);
        RestoreUserChoices(TempPreviousRecurringSyncBuffer);
        if not Rec.Get(CurrentEntryNo) then
            if Rec.FindFirst() then;
        CurrPage.Update(false);
        exit(HasSchedules);
    end;

    internal procedure CanFinish(): Boolean
    var
        TempRecurringSyncBuffer: Record "Shpfy Recurring Sync Buffer" temporary;
    begin
        TempRecurringSyncBuffer.Copy(Rec, true);
        TempRecurringSyncBuffer.Reset();
        TempRecurringSyncBuffer.SetRange(Selected, true);
        if not TempRecurringSyncBuffer.FindSet(false) then
            exit(false);
        repeat
            if not TempRecurringSyncBuffer.Selectable or (TempRecurringSyncBuffer.Frequency <= 0) then
                exit(false);
        until TempRecurringSyncBuffer.Next() = 0;
        exit(true);
    end;

    internal procedure CreateSchedules(): Text
    var
        TempRecurringSyncBuffer: Record "Shpfy Recurring Sync Buffer" temporary;
        NoSynchronizationSelectedErr: Label 'Select at least one synchronization to schedule.';
    begin
        TempRecurringSyncBuffer.Copy(Rec, true);
        TempRecurringSyncBuffer.Reset();
        TempRecurringSyncBuffer.SetRange(Selected, true);
        if TempRecurringSyncBuffer.IsEmpty() then
            Error(NoSynchronizationSelectedErr);
        exit(ScheduleMgt.CreateSelectedSchedules(Shop, TempRecurringSyncBuffer));
    end;

    local procedure RestoreUserChoices(var TempPreviousRecurringSyncBuffer: Record "Shpfy Recurring Sync Buffer" temporary)
    begin
        if Rec.FindSet() then
            repeat
                if Rec.Selectable then
                    if TempPreviousRecurringSyncBuffer.Get(Rec."Entry No.") then
                        if TempPreviousRecurringSyncBuffer.Selectable then begin
                            Rec.Selected := TempPreviousRecurringSyncBuffer.Selected;
                            Rec.Frequency := TempPreviousRecurringSyncBuffer.Frequency;
                            Rec.Modify(false);
                        end;
            until Rec.Next() = 0;
    end;
}
