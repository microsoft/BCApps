// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Capacity;

codeunit 99000759 "Calendar Absence Management"
{

    trigger OnRun()
    begin
    end;

    var
        Remove: Boolean;

    procedure UpdateAbsence(var CalAbsentEntry: Record "Calendar Absence Entry")
    var
        CalendarEntry: Record "Calendar Entry";
        CalendarEntry2: Record "Calendar Entry";
        CalendarEntry3: Record "Calendar Entry";
        AbsenceStartingDateTime: DateTime;
        Finished: Boolean;
    begin
        AbsenceStartingDateTime := CalAbsentEntry."Starting Date-Time";
        CalendarEntry.SetCurrentKey("Capacity Type", "No.", "Starting Date-Time");
        CalendarEntry.SetRange("Capacity Type", CalAbsentEntry."Capacity Type");
        CalendarEntry.SetRange("No.", CalAbsentEntry."No.");
        CalendarEntry.SetFilter("Starting Date-Time", '<%1', CalAbsentEntry."Ending Date-Time");
        CalendarEntry.SetFilter("Ending Date-Time", '>%1', CalAbsentEntry."Starting Date-Time");
        if Remove then
            CalendarEntry.SetFilter("Absence Capacity", '>%1', 0);
        if CalendarEntry.Find('-') then
            repeat
                Finished := false;
                CalendarEntry2 := CalendarEntry;
                CalendarEntry3 := CalendarEntry;
                CalendarEntry.Delete();
                if CalendarEntry."Starting Date-Time" < CalAbsentEntry."Starting Date-Time" then begin
                    CalendarEntry2.Validate("Ending Date-Time", CalAbsentEntry."Starting Date-Time");
                    CalendarEntry2.Insert();
                end else
                    CalAbsentEntry."Starting Date-Time" := CalendarEntry."Starting Date-Time";

                if Remove then
                    if CalendarEntry2."Absence Capacity" < CalAbsentEntry.Capacity then
                        CalendarEntry2."Absence Capacity" := 0
                    else
                        CalendarEntry2."Absence Capacity" := CalendarEntry2."Absence Capacity" - CalAbsentEntry.Capacity
                else
                    if CalendarEntry2.Capacity > CalAbsentEntry.Capacity then
                        CalendarEntry2."Absence Capacity" := CalAbsentEntry.Capacity
                    else
                        CalendarEntry2."Absence Capacity" := CalendarEntry2.Capacity;

                if CalendarEntry."Ending Date-Time" < CalAbsentEntry."Ending Date-Time" then begin
                    CalendarEntry2.Validate("Ending Date-Time", CalendarEntry."Ending Date-Time");
                    CalendarEntry2.Validate("Starting Date-Time", CalAbsentEntry."Starting Date-Time");
                    CalendarEntry2.Insert();
                    CalendarEntry := CalendarEntry2;
                    CalAbsentEntry."Starting Date-Time" := CalendarEntry."Ending Date-Time";
                end else begin
                    CalendarEntry2.Validate("Ending Date-Time", CalAbsentEntry."Ending Date-Time");
                    CalendarEntry2.Validate("Starting Date-Time", CalAbsentEntry."Starting Date-Time");
                    CalendarEntry2.Insert();
                    if CalendarEntry3."Ending Date-Time" > CalAbsentEntry."Ending Date-Time" then begin
                        CalendarEntry3.Validate("Starting Date-Time", CalAbsentEntry."Ending Date-Time");
                        CalendarEntry3.Insert();
                        CalendarEntry := CalendarEntry3;
                    end;
                    Finished := true;
                end;

            until (CalendarEntry.Next() = 0) or Finished;

        CalAbsentEntry."Starting Date-Time" := AbsenceStartingDateTime;
        CalAbsentEntry.Updated := not Remove;

        if not Remove then
            CalAbsentEntry.Modify();

        GatherEntries(CalendarEntry3);

        OnAfterUpdateAbsence(CalAbsentEntry);
    end;

    procedure RemoveAbsence(var CalAbsentEntry: Record "Calendar Absence Entry")
    begin
        if not CalAbsentEntry.Updated then
            exit;
        Remove := true;
        UpdateAbsence(CalAbsentEntry);
        Remove := false;
    end;

    local procedure GatherEntries(CalendarEntry: Record "Calendar Entry")
    var
        CalendarEntry2: Record "Calendar Entry";
    begin
        CalendarEntry2.SetCurrentKey("Capacity Type", "No.", "Starting Date-Time");
        CalendarEntry2.SetRange("Capacity Type", CalendarEntry."Capacity Type");
        CalendarEntry2.SetRange("No.", CalendarEntry."No.");
        CalendarEntry2.SetRange(Date, CalendarEntry.Date);
        if not CalendarEntry2.Find('-') then
            exit;

        CalendarEntry := CalendarEntry2;
        if CalendarEntry2.Next() = 0 then
            exit;

        repeat
            if (CalendarEntry.Efficiency = CalendarEntry2.Efficiency) and
               (CalendarEntry.Capacity = CalendarEntry2.Capacity) and
               (CalendarEntry."Absence Efficiency" = CalendarEntry2."Absence Efficiency") and
               (CalendarEntry."Absence Capacity" = CalendarEntry2."Absence Capacity") and
               (CalendarEntry.Date = CalendarEntry2.Date) and
               (CalendarEntry."Work Shift Code" = CalendarEntry2."Work Shift Code") and
               (CalendarEntry."Ending Date-Time" = CalendarEntry2."Starting Date-Time")
            then begin
                CalendarEntry2.Delete();
                CalendarEntry.Delete();
                CalendarEntry2.Validate("Starting Date-Time", CalendarEntry."Starting Date-Time");
                CalendarEntry2.Insert();
            end;
            CalendarEntry := CalendarEntry2;
        until CalendarEntry2.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateAbsence(var CalendarAbsenceEntry: Record "Calendar Absence Entry")
    begin
    end;
}

