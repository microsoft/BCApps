// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Capacity;

using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.WorkCenter;

table 99000848 "Registered Absence"
{
    Caption = 'Registered Absence';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Capacity Type"; Enum "Capacity Type")
        {
            Caption = 'Capacity Type';
            ToolTip = 'Specifies if the absence entry is related to a machine center or a work center.';
        }
        field(2; "No."; Code[20])
        {
            Caption = 'No.';
            ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
            TableRelation = if ("Capacity Type" = const("Work Center")) "Work Center"
            else
            if ("Capacity Type" = const("Machine Center")) "Machine Center";
        }
        field(3; Date; Date)
        {
            Caption = 'Date';
            ToolTip = 'Specifies the date of the absence. If the absence covers several days, there will be an entry line for each day.';
        }
        field(4; "Starting Time"; Time)
        {
            Caption = 'Starting Time';
            ToolTip = 'Specifies the starting time of the absence, such as the time the employee normally starts to work or the time the machine starts to operate.';

            trigger OnValidate()
            begin
                if ("Ending Time" = 0T) or
                   ("Ending Time" < "Starting Time")
                then
                    Validate("Ending Time", "Starting Time");

                "Starting Date-Time" := CreateDateTime(Date, "Starting Time");
            end;
        }
        field(5; "Ending Time"; Time)
        {
            Caption = 'Ending Time';
            ToolTip = 'Specifies the ending time of day of the absence, such as the time the employee normally leaves, or the time the machine stops operating.';

            trigger OnValidate()
            begin
                if "Ending Time" < "Starting Time" then
                    Error(Text002, FieldCaption("Ending Time"), FieldCaption("Starting Time"));

                "Ending Date-Time" := CreateDateTime(Date, "Ending Time");
            end;
        }
        field(6; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a short description of the reason for the absence.';
        }
        field(7; Capacity; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Capacity';
            ToolTip = 'Specifies the amount of capacity, which cannot be used during the absence period.';
            MinValue = 0;
        }
        field(8; "Starting Date-Time"; DateTime)
        {
            Caption = 'Starting Date-Time';
            ToolTip = 'Specifies the date and the starting time, which are combined in a format called "starting date-time".';

            trigger OnValidate()
            begin
                "Starting Time" := DT2Time("Starting Date-Time");
                Date := DT2Date("Starting Date-Time");
                Validate("Starting Time");
            end;
        }
        field(9; "Ending Date-Time"; DateTime)
        {
            Caption = 'Ending Date-Time';
            ToolTip = 'Specifies the date and the ending time, which are combined in a format called "ending date-time".';

            trigger OnValidate()
            begin
                "Ending Time" := DT2Time("Ending Date-Time");
                Date := DT2Date("Ending Date-Time");
                Validate("Ending Time");
            end;
        }
    }

    keys
    {
        key(Key1; "Capacity Type", "No.", Date, "Starting Time", "Ending Time")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        CheckSyntax();
    end;

    trigger OnModify()
    begin
        CheckSyntax();
    end;

    trigger OnRename()
    begin
        CheckSyntax();
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label '%1 must not be blank.';
        Text001: Label '%1 must be higher than %2';
        Text002: Label '%1 must be higher than %2.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    local procedure CheckSyntax()
    begin
        if Date = 0D then
            Error(Text000, FieldCaption(Date));
        if "Starting Time" = 0T then
            Error(Text000, FieldCaption("Starting Time"));
        if "Ending Time" = 0T then
            Error(Text000, FieldCaption("Ending Time"));
        if "Starting Time" > "Ending Time" then
            Error(Text001, FieldCaption("Ending Time"), FieldCaption("Starting Time"));
    end;

    procedure UpdateDatetime()
    begin
        "Starting Date-Time" := CreateDateTime(Date, "Starting Time");
        "Ending Date-Time" := CreateDateTime(Date, "Ending Time");
    end;
}

