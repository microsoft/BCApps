// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.WorkCenter;

using Microsoft.Manufacturing.Capacity;

report 99001046 "Calculate Work Center Calendar"
{
    Caption = 'Calculate Work Center Calendar';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Work Center"; "Work Center")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.";

            trigger OnAfterGetRecord()
            begin
                Window.Update(1, "No.");

                TestField(Efficiency);

                Calendar.Reset();
                Calendar.SetRange("Capacity Type", Calendar."Capacity Type"::"Work Center");
                Calendar.SetRange("No.", "No.");
                Calendar.SetRange(Date, StartingDate, EndingDate);
                Calendar.DeleteAll();

                OnAfterDeleteWorkCenterCalendarEntries("Work Center", StartingDate, EndingDate);

                if "Consolidated Calendar" then begin
                    Calendar.SetRange("No.");
                    Calendar.SetCurrentKey("Work Center No.", Date);
                    Calendar.SetRange("Work Center No.", "No.");
                    Calendar.SetRange("Capacity Type", Calendar."Capacity Type"::"Machine Center");
                    if Calendar.Find('-') then
                        repeat
                            TempCalendar.Init();
                            TempCalendar."Capacity Type" := Calendar."Capacity Type"::"Work Center";
                            TempCalendar."No." := "No.";
                            TempCalendar."Work Center No." := "No.";
                            TempCalendar.Date := Calendar.Date;
                            TempCalendar."Starting Time" := Calendar."Starting Time";
                            if TempCalendar.Insert() then;
                            TempCalendar."Starting Time" := Calendar."Ending Time";
                            if TempCalendar.Insert() then;
                        until Calendar.Next() = 0;

                    Calendar.Reset();
                    Calendar.SetCurrentKey("Work Center No.", Date);
                    Calendar.SetRange("Capacity Type", Calendar."Capacity Type"::"Machine Center");
                    Calendar.SetRange("Work Center No.", "No.");
                    TempCalendar.SetRange("Work Center No.", "No.");
                    if TempCalendar.Find('-') then
                        repeat
                            Clear(LastTime);
                            TempCalendar.SetRange(Date, TempCalendar.Date);
                            Calendar.SetRange(Date, TempCalendar.Date);
                            if TempCalendar.Find('-') then
                                repeat
                                    if LastTime = 0T then
                                        LastTime := TempCalendar."Starting Time"
                                    else begin
                                        Calendar.SetFilter("Starting Time", '<=%1', LastTime);
                                        Calendar.SetFilter("Ending Time", '>%1', LastTime);
                                        if Calendar.Find('-') then begin
                                            Calendar2 := TempCalendar;
                                            Calendar2."Work Shift Code" := '';
                                            Calendar2."Starting Time" := LastTime;
                                            Calendar2.Validate("Ending Time", TempCalendar."Starting Time");
                                            Calendar2.Validate("No.");
                                            Calendar2.Capacity := 0;
                                            repeat
                                                Calendar2.Capacity := Calendar2.Capacity + (Calendar.Capacity - Calendar."Absence Capacity") *
                                                  Calendar.Efficiency / 100;
                                            until Calendar.Next() = 0;
                                            if Calendar2.Capacity <> 0 then begin
                                                Calendar2.Validate(Capacity);
                                                Calendar2.Insert();
                                            end;
                                        end;
                                        LastTime := TempCalendar."Starting Time";
                                    end;
                                until TempCalendar.Next() = 0;
                            TempCalendar.SetRange(Date);
                        until TempCalendar.Next() = 0;
                end else begin
                    TestField(Capacity);
                    TestField("Unit of Measure Code");

                    CalendarMgt.CalculateSchedule(Enum::"Capacity Type"::"Work Center", "No.", "No.", StartingDate, EndingDate);
                end;
            end;

            trigger OnPreDataItem()
            begin
                if StartingDate = 0D then
                    Error(Text004);

                if EndingDate = 0D then
                    Error(Text005);
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(StartingDate; StartingDate)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the date that you will start creating new calendar entries.';
                    }
                    field(EndingDate; EndingDate)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the final date that you will create new calendar entries.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            if StartingDate = 0D then
                StartingDate := DMY2Date(1, 1, Date2DMY(WorkDate(), 3));
            if EndingDate = 0D then
                EndingDate := DMY2Date(31, 12, Date2DMY(WorkDate(), 3));
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        Window.Open(
          Text000 +
          Text001);
    end;

    var
        Calendar: Record "Calendar Entry";
        Calendar2: Record "Calendar Entry";
        TempCalendar: Record "Calendar Entry" temporary;
        CalendarMgt: Codeunit "Shop Calendar Management";
        Window: Dialog;
        StartingDate: Date;
        EndingDate: Date;
        LastTime: Time;

#pragma warning disable AA0074
        Text000: Label 'Calculating Work Centers...\\';
#pragma warning disable AA0470
        Text001: Label 'No.            #1##########';
#pragma warning restore AA0470
        Text004: Label 'You must fill in the starting date field.';
        Text005: Label 'You must fill in the ending date field.';
#pragma warning restore AA0074

    procedure InitializeRequest(NewStartingDate: Date; NewEndingDate: Date)
    begin
        StartingDate := NewStartingDate;
        EndingDate := NewEndingDate;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeleteWorkCenterCalendarEntries(var WorkCenter: Record "Work Center"; StartingDate: Date; EndingDate: Date)
    begin
    end;
}

