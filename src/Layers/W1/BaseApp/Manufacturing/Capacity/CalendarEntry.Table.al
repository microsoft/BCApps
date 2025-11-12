// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Capacity;

using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.WorkCenter;

table 99000757 "Calendar Entry"
{
    Caption = 'Calendar Entry';
    DrillDownPageID = "Calendar Entries";
    LookupPageID = "Calendar Entries";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Capacity Type"; Enum "Capacity Type")
        {
            Caption = 'Capacity Type';

            trigger OnValidate()
            begin
                "No." := '';
                "Work Center No." := '';
                "Work Center Group Code" := '';
            end;
        }
        field(2; "No."; Code[20])
        {
            Caption = 'No.';
            NotBlank = true;
            TableRelation = if ("Capacity Type" = const("Work Center")) "Work Center"
            else
            if ("Capacity Type" = const("Machine Center")) "Machine Center";

            trigger OnValidate()
            begin
                if "No." = '' then
                    exit;

                case "Capacity Type" of
                    "Capacity Type"::"Work Center":
                        begin
                            WorkCenter.Get("No.");
                            WorkCenter.TestField("Work Center Group Code");
                            "Work Center No." := WorkCenter."No.";
                            "Work Center Group Code" := WorkCenter."Work Center Group Code";
                            Efficiency := WorkCenter.Efficiency;
                            if not WorkCenter."Consolidated Calendar" then
                                Capacity := WorkCenter.Capacity;
                        end;
                    "Capacity Type"::"Machine Center":
                        begin
                            MachineCenter.Get("No.");
                            MachineCenter.TestField("Work Center No.");
                            WorkCenter.Get(MachineCenter."Work Center No.");
                            WorkCenter.TestField("Work Center Group Code");
                            "Work Center No." := WorkCenter."No.";
                            "Work Center Group Code" := WorkCenter."Work Center Group Code";
                            Efficiency := MachineCenter.Efficiency;
                            Capacity := MachineCenter.Capacity;
                        end;
                end;
                if "Ending Time" <> 0T then
                    Validate("Ending Time");
            end;
        }
        field(4; Date; Date)
        {
            Caption = 'Date';
            NotBlank = true;

            trigger OnValidate()
            begin
                CheckRedundancy();
            end;
        }
        field(5; "Work Shift Code"; Code[10])
        {
            Caption = 'Work Shift Code';
            NotBlank = true;
            TableRelation = "Work Shift";

            trigger OnValidate()
            begin
                CheckRedundancy();
            end;
        }
        field(6; "Starting Time"; Time)
        {
            Caption = 'Starting Time';
            NotBlank = true;

            trigger OnValidate()
            begin
                if ("Ending Time" = 0T) or
                   ("Ending Time" < "Starting Time")
                then begin
                    CalendarEntry.Reset();
                    CalendarEntry.SetRange("Capacity Type", "Capacity Type");
                    CalendarEntry.SetRange("No.", "No.");
                    CalendarEntry.SetRange(Date, Date);
                    CalendarEntry.SetRange("Starting Time", "Starting Time", 235959T);
                    if CalendarEntry.Find('-') then
                        "Ending Time" := CalendarEntry."Starting Time"
                    else
                        "Ending Time" := 235959T;
                end;
                Validate("Ending Time");
            end;
        }
        field(7; "Ending Time"; Time)
        {
            Caption = 'Ending Time';
            NotBlank = true;

            trigger OnValidate()
            begin
                if ("Ending Time" < "Starting Time") and
                   ("Ending Time" <> 000000T)
                then
                    Error(Text000, FieldCaption("Ending Time"), FieldCaption("Starting Time"));

                CalculateCapacity();

                CheckRedundancy();

                UpdateDatetime();
            end;
        }
        field(8; "Work Center No."; Code[20])
        {
            Caption = 'Work Center No.';
            Editable = false;
            TableRelation = "Work Center";
        }
        field(9; "Work Center Group Code"; Code[10])
        {
            Caption = 'Work Center Group Code';
            Editable = false;
            TableRelation = "Work Center Group";
        }
        field(10; "Capacity (Total)"; Decimal)
        {
            Caption = 'Capacity (Total)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(11; "Capacity (Effective)"; Decimal)
        {
            Caption = 'Capacity (Effective)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(20; Efficiency; Decimal)
        {
            Caption = 'Efficiency';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                "Capacity (Effective)" := Round("Capacity (Total)" * Efficiency / 100, 0.001);
            end;
        }
        field(21; Capacity; Decimal)
        {
            Caption = 'Capacity';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                CalculateCapacity();
            end;
        }
        field(22; "Absence Efficiency"; Decimal)
        {
            Caption = 'Absence Efficiency';
            DecimalPlaces = 0 : 5;
            Editable = false;
            MinValue = 0;

            trigger OnValidate()
            begin
                "Capacity (Effective)" := Round("Capacity (Total)" * Efficiency / 100, 0.001);
            end;
        }
        field(23; "Absence Capacity"; Decimal)
        {
            Caption = 'Absence Capacity';
            DecimalPlaces = 0 : 5;
            Editable = false;
            MinValue = 0;

            trigger OnValidate()
            begin
                CalculateCapacity();
            end;
        }
        field(24; "Starting Date-Time"; DateTime)
        {
            Caption = 'Starting Date-Time';

            trigger OnValidate()
            begin
                Date := DT2Date("Starting Date-Time");
                Validate("Starting Time", DT2Time("Starting Date-Time"));
            end;
        }
        field(25; "Ending Date-Time"; DateTime)
        {
            Caption = 'Ending Date-Time';

            trigger OnValidate()
            begin
                Date := DT2Date("Ending Date-Time");
                Validate("Ending Time", DT2Time("Ending Date-Time"));
            end;
        }
    }

    keys
    {
        key(Key1; "Capacity Type", "No.", Date, "Starting Time", "Ending Time", "Work Shift Code")
        {
            Clustered = true;
        }
        key(Key2; "Work Center No.", Date, "Work Shift Code")
        {
            SumIndexFields = "Capacity (Total)", "Capacity (Effective)";
        }
        key(Key3; "Work Center Group Code", Date, "Work Shift Code")
        {
            SumIndexFields = "Capacity (Total)", "Capacity (Effective)";
        }
        key(Key4; "Capacity Type", "No.", "Starting Date-Time", "Ending Date-Time", "Absence Capacity")
        {
        }
        key(Key5; "Capacity Type", "No.", "Ending Date-Time", "Starting Date-Time")
        {
        }
    }

    fieldgroups
    {
    }

    var
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
        CalendarEntry: Record "Calendar Entry";
        CalendarMgt: Codeunit "Shop Calendar Management";

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label '%1 must be higher than %2.';
        Text001: Label 'There is redundancy in %1 within the calendar of %2. From %3 to %4. Conflicting time from %5 to %6.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    local procedure CheckRedundancy()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckRedundancy(Rec, IsHandled);
        if IsHandled then
            exit;

        if ("Starting Time" = 0T) and ("Ending Time" = 0T) then
            exit;

        CalendarEntry.SetRange("Capacity Type", "Capacity Type");
        CalendarEntry.SetRange("No.", "No.");
        CalendarEntry.SetRange(Date, Date);
        CalendarEntry.SetFilter("Starting Time", '<%1', "Ending Time");
        CalendarEntry.SetFilter("Ending Time", '>%1|%2', "Starting Time", 000000T);
        OnCheckRedundancyOnAfterCalendarEntrySetFilters(Rec, CalendarEntry);

        if CalendarEntry.Find('-') then
            repeat
                if (CalendarEntry."Starting Time" <> xRec."Starting Time") or
                   (CalendarEntry."Ending Time" <> xRec."Ending Time") or
                   (CalendarEntry."Work Shift Code" <> xRec."Work Shift Code")
                then
                    Error(
                      Text001,
                      "Capacity Type",
                      "No.",
                      "Starting Time",
                      "Ending Time",
                      CalendarEntry."Starting Time",
                      CalendarEntry."Ending Time");
            until CalendarEntry.Next() = 0;
    end;

    local procedure CalculateCapacity()
    begin
        WorkCenter.Get("Work Center No.");

        if ("Starting Time" = 0T) and
           ("Ending Time" = 0T)
        then begin
            Validate("Capacity (Total)", 0);
            exit;
        end;

        "Capacity (Total)" :=
          Round(
            CalendarMgt.CalcTimeDelta("Ending Time", "Starting Time") /
            CalendarMgt.TimeFactor(WorkCenter."Unit of Measure Code") *
            (Capacity - "Absence Capacity"), WorkCenter."Calendar Rounding Precision");

        "Capacity (Effective)" := Round("Capacity (Total)" * Efficiency / 100, WorkCenter."Calendar Rounding Precision");
    end;

    procedure Caption(): Text
    var
        FilterText: Text;
    begin
        FilterText := GetFilter("No.");
        if FilterText = '' then
            exit('');

        if "Capacity Type" = "Capacity Type"::"Machine Center" then begin
            MachineCenter.SetFilter("No.", FilterText);
            if not MachineCenter.FindFirst() then
                exit('');
            exit(StrSubstNo('%1 %2', MachineCenter."No.", MachineCenter.Name));
        end;
        WorkCenter.SetFilter("No.", FilterText);
        if not WorkCenter.FindFirst() then
            exit('');
        exit(StrSubstNo('%1 %2', WorkCenter."No.", WorkCenter.Name));
    end;

    local procedure UpdateDatetime()
    begin
        "Starting Date-Time" := CreateDateTime(Date, "Starting Time");
        "Ending Date-Time" := CreateDateTime(Date, "Ending Time");
    end;

    [Scope('OnPrem')]
    procedure GetStartingEndingDateAndTime(var StartingTime: Time; var EndingTime: Time; var CurrDate: Date)
    begin
        StartingTime := DT2Time("Starting Date-Time");
        EndingTime := DT2Time("Ending Date-Time");
        CurrDate := DT2Date("Ending Date-Time");
    end;

    procedure SetCapacityFilters(CapType: Enum "Capacity Type"; CapNo: Code[20])
    begin
        Reset();
        SetCurrentKey("Capacity Type", "No.", "Starting Date-Time", "Ending Date-Time");
        SetRange("Capacity Type", CapType);
        SetRange("No.", CapNo);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckRedundancy(var CalendarEntry: Record "Calendar Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckRedundancyOnAfterCalendarEntrySetFilters(CalendarEntryRec: Record "Calendar Entry"; var CalendarEntry: Record "Calendar Entry")
    begin
    end;
}

