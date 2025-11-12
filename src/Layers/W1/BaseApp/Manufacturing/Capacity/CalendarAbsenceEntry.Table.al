// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Capacity;

using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.WorkCenter;

table 99000760 "Calendar Absence Entry"
{
    Caption = 'Calendar Absence Entry';
    DrillDownPageID = "Capacity Absence";
    LookupPageID = "Capacity Absence";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Capacity Type"; Enum "Capacity Type")
        {
            Caption = 'Capacity Type';
            Editable = false;
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
                            Workcenter.Get("No.");
                            Workcenter.TestField("Work Center Group Code");
                            "Work Center No." := Workcenter."No.";
                            "Work Center Group Code" := Workcenter."Work Center Group Code";
                            Capacity := Workcenter.Capacity;
                        end;
                    "Capacity Type"::"Machine Center":
                        begin
                            Machinecenter.Get("No.");
                            Machinecenter.TestField("Work Center No.");
                            Workcenter.Get(Machinecenter."Work Center No.");
                            Workcenter.TestField("Work Center Group Code");
                            "Work Center No." := Workcenter."No.";
                            "Work Center Group Code" := Workcenter."Work Center Group Code";
                            Capacity := Machinecenter.Capacity;
                        end;
                end;
            end;
        }
        field(4; Date; Date)
        {
            Caption = 'Date';
            NotBlank = true;

            trigger OnValidate()
            begin
                UpdateDatetime();
            end;
        }
        field(6; "Starting Time"; Time)
        {
            Caption = 'Starting Time';

            trigger OnValidate()
            begin
                if ("Ending Time" = 0T) or
                   ("Ending Time" < "Starting Time")
                then
                    Validate("Ending Time", "Starting Time")
            end;
        }
        field(7; "Ending Time"; Time)
        {
            Caption = 'Ending Time';

            trigger OnValidate()
            begin
                if "Ending Time" < "Starting Time" then
                    Error(Text000, FieldCaption("Ending Time"), FieldCaption("Starting Time"));

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
        field(21; Capacity; Decimal)
        {
            Caption = 'Capacity';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                if Capacity <> xRec.Capacity then begin
                    CalAbsenceMgt.RemoveAbsence(xRec);
                    Updated := false;
                end;
            end;
        }
        field(24; "Starting Date-Time"; DateTime)
        {
            Caption = 'Starting Date-Time';

            trigger OnValidate()
            begin
                "Starting Time" := DT2Time("Starting Date-Time");
                Date := DT2Date("Starting Date-Time");
                Validate("Starting Time");
            end;
        }
        field(25; "Ending Date-Time"; DateTime)
        {
            Caption = 'Ending Date-Time';

            trigger OnValidate()
            begin
                "Ending Time" := DT2Time("Ending Date-Time");
                Date := DT2Date("Ending Date-Time");
                Validate("Ending Time");
            end;
        }
        field(31; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(32; Updated; Boolean)
        {
            Caption = 'Updated';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Capacity Type", "No.", Date, "Starting Time", "Ending Time")
        {
            Clustered = true;
        }
        key(Key2; "Work Center No.")
        {
        }
        key(Key3; "Capacity Type", "No.", Date, "Starting Date-Time", "Ending Date-Time")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        CalAbsenceMgt.RemoveAbsence(Rec);
    end;

    trigger OnRename()
    begin
        CalAbsenceMgt.RemoveAbsence(xRec);
        Updated := false;
    end;

    var
        Workcenter: Record "Work Center";
        Machinecenter: Record "Machine Center";
        CalAbsenceMgt: Codeunit "Calendar Absence Management";

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label '%1 must be higher than %2.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure Caption(): Text
    begin
        if "Capacity Type" = "Capacity Type"::"Machine Center" then begin
            if not Machinecenter.Get(GetFilter("No.")) then
                exit('');
            exit(
              StrSubstNo('%1 %2',
                Machinecenter."No.", Machinecenter.Name));
        end;
        if not Workcenter.Get(GetFilter("No.")) then
            exit('');
        exit(
          StrSubstNo('%1 %2',
            Workcenter."No.", Workcenter.Name));
    end;

    local procedure UpdateDatetime()
    begin
        "Starting Date-Time" := CreateDateTime(Date, "Starting Time");
        "Ending Date-Time" := CreateDateTime(Date, "Ending Time");
    end;
}

