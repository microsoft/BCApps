// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Capacity;

table 99000753 "Shop Calendar Holiday"
{
    Caption = 'Shop Calendar Holiday';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Shop Calendar Code"; Code[10])
        {
            Caption = 'Shop Calendar Code';
            NotBlank = true;
            TableRelation = "Shop Calendar";
        }
        field(2; Date; Date)
        {
            Caption = 'Date';
            ToolTip = 'Specifies the date to set up as a shop calendar holiday.';
            NotBlank = true;

            trigger OnValidate()
            begin
                "Starting Date-Time" := CreateDateTime(Date, "Starting Time");
                if "Ending Date-Time" <> 0DT then
                    "Ending Date-Time" := CreateDateTime(Date, "Ending Time");
            end;
        }
        field(3; "Starting Time"; Time)
        {
            Caption = 'Starting Time';
            ToolTip = 'Specifies the starting time of the shop calendar holiday.';

            trigger OnValidate()
            begin
                if ("Ending Time" = 0T) or
                   ("Ending Time" < "Starting Time")
                then
                    "Ending Time" := "Starting Time";

                Validate("Ending Time");
            end;
        }
        field(4; "Ending Time"; Time)
        {
            Caption = 'Ending Time';
            ToolTip = 'Specifies the ending time of the shop calendar holiday.';

            trigger OnValidate()
            begin
                if "Ending Time" < "Starting Time" then
                    Error(Text000, FieldCaption("Ending Time"), FieldCaption("Starting Time"));

                UpdateDatetime();
            end;
        }
        field(5; "Starting Date-Time"; DateTime)
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
        field(6; "Ending Date-Time"; DateTime)
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
        field(10; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the description of the shop calendar holiday.';
        }
    }

    keys
    {
        key(Key1; "Shop Calendar Code", Date)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label '%1 must be higher than %2.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    local procedure UpdateDatetime()
    begin
        "Starting Date-Time" := CreateDateTime(Date, "Starting Time");
        "Ending Date-Time" := CreateDateTime(Date, "Ending Time");
    end;
}

