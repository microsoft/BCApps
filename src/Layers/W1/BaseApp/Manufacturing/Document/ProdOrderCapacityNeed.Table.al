// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Document;

using Microsoft.Inventory.Requisition;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.WorkCenter;

table 5410 "Prod. Order Capacity Need"
{
    Caption = 'Prod. Order Capacity Need';
    DrillDownPageID = "Prod. Order Capacity Need";
    LookupPageID = "Prod. Order Capacity Need";
    DataClassification = CustomerContent;

    fields
    {
        field(1; Status; Enum "Production Order Status")
        {
            Caption = 'Status';
        }
        field(2; "Prod. Order No."; Code[20])
        {
            Caption = 'Prod. Order No.';
            TableRelation = "Production Order"."No." where(Status = field(Status));
            ValidateTableRelation = false;
        }
        field(3; "Routing No."; Code[20])
        {
            Caption = 'Routing No.';
            TableRelation = "Routing Header";
        }
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(5; "Operation No."; Code[10])
        {
            Caption = 'Operation No.';
        }
        field(6; Type; Enum "Capacity Type")
        {
            Caption = 'Type';
        }
        field(7; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = if (Type = const("Work Center")) "Work Center"
            else
            if (Type = const("Machine Center")) "Machine Center";
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
        field(10; "Routing Reference No."; Integer)
        {
            Caption = 'Routing Reference No.';
        }
        field(11; Date; Date)
        {
            Caption = 'Date';
        }
        field(12; "Starting Time"; Time)
        {
            Caption = 'Starting Time';
        }
        field(13; "Ending Time"; Time)
        {
            Caption = 'Ending Time';
        }
        field(14; "Allocated Time"; Decimal)
        {
            Caption = 'Allocated Time';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(16; "Send-Ahead Type"; Option)
        {
            Caption = 'Send-Ahead Type';
            OptionCaption = ' ,Input,Output,Both';
            OptionMembers = " ",Input,Output,Both;
        }
#pragma warning disable AS0070 // Time type changed from Setup to "Setup Time" due to implementation of enum
        field(17; "Time Type"; Enum "Routing Time Type")
        {
            Caption = 'Time Type';
        }
#pragma warning restore AS0070
        field(18; "Needed Time"; Decimal)
        {
            Caption = 'Needed Time';
            DecimalPlaces = 0 : 5;
        }
        field(19; "Needed Time (ms)"; Decimal)
        {
            Caption = 'Needed Time (ms)';
            Editable = false;
        }
        field(21; "Lot Size"; Decimal)
        {
            Caption = 'Lot Size';
            DecimalPlaces = 1 : 1;
        }
        field(22; "Concurrent Capacities"; Decimal)
        {
            Caption = 'Concurrent Capacities';
            DecimalPlaces = 0 : 5;
        }
        field(23; Efficiency; Decimal)
        {
            Caption = 'Efficiency';
            DecimalPlaces = 0 : 5;
        }
        field(26; "Starting Date-Time"; DateTime)
        {
            Caption = 'Starting Date-Time';
            Editable = false;
        }
        field(27; "Ending Date-Time"; DateTime)
        {
            Caption = 'Ending Date-Time';
            Editable = false;
        }
        field(31; "Worksheet Template Name"; Code[10])
        {
            Caption = 'Worksheet Template Name';
            TableRelation = "Req. Wksh. Template";
        }
        field(32; "Worksheet Batch Name"; Code[10])
        {
            Caption = 'Worksheet Batch Name';
            TableRelation = "Requisition Wksh. Name".Name where("Worksheet Template Name" = field("Worksheet Template Name"));
        }
        field(33; "Worksheet Line No."; Integer)
        {
            Caption = 'Worksheet Line No.';
            TableRelation = "Requisition Line"."Line No." where("Worksheet Template Name" = field("Worksheet Template Name"),
                                                                 "Journal Batch Name" = field("Worksheet Batch Name"));
        }
        field(41; Active; Boolean)
        {
            Caption = 'Active';
            Editable = false;
        }
        field(42; "Requested Only"; Boolean)
        {
            Caption = 'Requested Only';
        }
    }

    keys
    {
        key(Key1; Status, "Prod. Order No.", "Requested Only", "Routing No.", "Routing Reference No.", "Operation No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Prod. Order No.", "Routing No.", "Routing Reference No.", "Operation No.", Status, "Line No.", "Requested Only")
        {
        }
        key(Key3; Status, "Prod. Order No.", Active, "Requested Only", "Routing No.")
        {
        }
        key(Key4; "Work Center No.", Date, Active, "Starting Date-Time")
        {
            IncludedFields = "Allocated Time", "Needed Time";
        }
        key(Key5; "Work Center Group Code", Date, "Starting Date-Time")
        {
            IncludedFields = "Allocated Time";
        }
        key(Key6; Type, "No.", Date, Active)
        {
            IncludedFields = "Allocated Time";
        }
        key(Key7; Type, "No.", "Starting Date-Time", "Ending Date-Time", Active)
        {
        }
        key(Key8; Type, "No.", "Ending Date-Time", "Starting Date-Time", Active)
        {
        }
        key(Key9; "Worksheet Template Name", "Worksheet Batch Name", "Worksheet Line No.", "Operation No.")
        {
            IncludedFields = "Allocated Time";
        }
        key(Key10; Status, "Prod. Order No.", "Routing Reference No.", "Operation No.", Date, "Starting Time")
        {
        }
        key(Key11; "Worksheet Template Name", "Worksheet Batch Name", "Worksheet Line No.", "Operation No.", Date, "Starting Time")
        {
            MaintainSQLIndex = false;
        }
        key(Key12; "Worksheet Line No.", "Operation No.")
        {
        }
        key(Key13; Status, "Prod. Order No.", Type, "No.", "Work Center No.", Date, "Requested Only")
        {
            IncludedFields = "Allocated Time", "Needed Time";
        }
    }

    fieldgroups
    {
    }

    procedure UpdateDatetime()
    begin
        if (Date <> 0D) and ("Starting Time" <> 0T) then
            "Starting Date-Time" := CreateDateTime(Date, "Starting Time")
        else
            "Starting Date-Time" := 0DT;

        if (Date <> 0D) and ("Ending Time" <> 0T) then
            "Ending Date-Time" := CreateDateTime(Date, "Ending Time")
        else
            "Ending Date-Time" := 0DT;
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
        SetCurrentKey(Type, "No.", "Ending Date-Time", "Starting Date-Time");
        SetRange(Type, CapType);
        SetRange("No.", CapNo);
        SetFilter(Status, '<> %1', Status::Simulated);
        SetFilter("Allocated Time", '> 0');
    end;
}

