// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Setup;

table 5954 "Work-Hour Template"
{
    Caption = 'Work-Hour Template';
    LookupPageID = "Work-Hour Templates";
    ReplicateData = true;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            ToolTip = 'Specifies a code for the work-hour template.';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the work-hour template.';
        }
        field(3; Monday; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Monday';
            ToolTip = 'Specifies the number of work-hours on Monday.';
            DecimalPlaces = 0 : 5;
            MaxValue = 24;
            MinValue = 0;

            trigger OnValidate()
            begin
                CalculateWeekTotal();
            end;
        }
        field(4; Tuesday; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Tuesday';
            ToolTip = 'Specifies the number of work-hours on Tuesday.';
            DecimalPlaces = 0 : 5;
            MaxValue = 24;
            MinValue = 0;

            trigger OnValidate()
            begin
                CalculateWeekTotal();
            end;
        }
        field(5; Wednesday; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Wednesday';
            ToolTip = 'Specifies the number of work-hours on Wednesday.';
            DecimalPlaces = 0 : 5;
            MaxValue = 24;
            MinValue = 0;

            trigger OnValidate()
            begin
                CalculateWeekTotal();
            end;
        }
        field(6; Thursday; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Thursday';
            ToolTip = 'Specifies the number of work-hours on Thursday.';
            DecimalPlaces = 0 : 5;
            MaxValue = 24;
            MinValue = 0;

            trigger OnValidate()
            begin
                CalculateWeekTotal();
            end;
        }
        field(7; Friday; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Friday';
            ToolTip = 'Specifies the number of work-hours on Friday.';
            DecimalPlaces = 0 : 5;
            MaxValue = 24;
            MinValue = 0;

            trigger OnValidate()
            begin
                CalculateWeekTotal();
            end;
        }
        field(8; Saturday; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Saturday';
            ToolTip = 'Specifies the number of work-hours on Saturday.';
            DecimalPlaces = 0 : 5;
            MaxValue = 24;
            MinValue = 0;

            trigger OnValidate()
            begin
                CalculateWeekTotal();
            end;
        }
        field(9; Sunday; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Sunday';
            ToolTip = 'Specifies the number of work-hours on Sunday.';
            DecimalPlaces = 0 : 5;
            MaxValue = 24;
            MinValue = 0;

            trigger OnValidate()
            begin
                CalculateWeekTotal();
            end;
        }
        field(10; "Total per Week"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Total per Week';
            ToolTip = 'Specifies the total number of work-hours per week for the work-hour template.';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure CalculateWeekTotal()
    begin
        "Total per Week" := Monday + Tuesday + Wednesday + Thursday + Friday + Saturday + Sunday;
    end;
}

