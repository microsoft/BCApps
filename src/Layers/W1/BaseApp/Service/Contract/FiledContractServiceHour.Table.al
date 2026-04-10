// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Contract;

table 5975 "Filed Contract Service Hour"
{
    Caption = 'Filed Contract Service Hour';
    LookupPageID = "Filed Contract Service Hours";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Service Contract No."; Code[20])
        {
            Caption = 'Service Contract No.';
            TableRelation = "Filed Service Contract Header"."Contract No." where("Contract Type" = field("Service Contract Type"));
            ToolTip = 'Specifies the number of the filed service contract to which the service hours apply.';
        }
        field(2; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
            ToolTip = 'Specifies the date when the service hours become valid.';
        }
        field(3; Day; Option)
        {
            Caption = 'Day';
            OptionCaption = 'Monday,Tuesday,Wednesday,Thursday,Friday,Saturday,Sunday';
            OptionMembers = Monday,Tuesday,Wednesday,Thursday,Friday,Saturday,Sunday;
            ToolTip = 'Specifies the day when the service hours are valid.';
        }
        field(4; "Starting Time"; Time)
        {
            Caption = 'Starting Time';
            ToolTip = 'Specifies the starting time of the service hours.';
        }
        field(5; "Ending Time"; Time)
        {
            Caption = 'Ending Time';
            ToolTip = 'Specifies the ending time of the service hours.';
        }
        field(6; "Valid on Holidays"; Boolean)
        {
            Caption = 'Valid on Holidays';
            ToolTip = 'Specifies that service hours are valid on holidays.';
        }
        field(7; "Service Contract Type"; Enum "Service Hour Contract Type")
        {
            Caption = 'Service Contract Type';
        }
        field(100; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            ToolTip = 'Specifies the unique number of filed service contract or service contract quote.';
        }
    }

    keys
    {
        key(Key1; "Entry No.", Day, "Starting Date")
        {
            Clustered = true;
        }
        key(Key2; "Service Contract Type", "Service Contract No.", Day, "Starting Date")
        {
        }
    }
}