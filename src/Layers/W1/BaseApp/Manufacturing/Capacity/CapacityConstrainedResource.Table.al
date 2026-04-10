// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Capacity;

using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.WorkCenter;

table 99000866 "Capacity Constrained Resource"
{
    Caption = 'Capacity Constrained Resource';
    Permissions = TableData "Prod. Order Capacity Need" = r;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Capacity No."; Code[20])
        {
            Caption = 'Capacity No.';
            ToolTip = 'Specifies the number of an existing machine center or work center to assign finite loading to.';
            TableRelation = if ("Capacity Type" = const("Work Center")) "Work Center"
            else
            if ("Capacity Type" = const("Machine Center")) "Machine Center";

            trigger OnValidate()
            begin
                if "Capacity No." = '' then
                    exit;

                case "Capacity Type" of
                    "Capacity Type"::"Work Center":
                        begin
                            WorkCenter.Get("Capacity No.");
                            WorkCenter.TestField(Blocked, false);
                            Name := WorkCenter.Name;
                            "Work Center No." := WorkCenter."No.";
                        end;
                    "Capacity Type"::"Machine Center":
                        begin
                            MachineCenter.Get("Capacity No.");
                            MachineCenter.TestField(Blocked, false);
                            Name := MachineCenter.Name;
                            "Work Center No." := MachineCenter."Work Center No.";
                        end
                end;

                "Critical Load %" := 100;
                "Dampener (% of Total Capacity)" := 0;
            end;
        }
        field(2; "Capacity Type"; Enum "Capacity Type")
        {
            Caption = 'Capacity Type';
            ToolTip = 'Specifies the capacity type to apply finite loading to.';

            trigger OnValidate()
            begin
                "Capacity No." := '';
            end;
        }
        field(3; Name; Text[100])
        {
            Caption = 'Name';
            ToolTip = 'Specifies the name of the work center or machine center associated with the capacity number on this line.';
        }
        field(10; "Critical Load %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Critical Load %';
            ToolTip = 'Specifies the percentage of the available capacity of a work center or machine center to apply load to. Operations on work centers or machine centers that are set up as constrained resources will always be planned serially. This means that if a constrained resource has multiple capacities, then those capacities can only be planned in sequence, not in parallel as they would be if the work or machine center was not set up as a constrained resource. In a constrained resource, the Capacity field on the work center or machine center is greater than 1.';
            DecimalPlaces = 1 : 1;

            trigger OnValidate()
            begin
                if "Critical Load %" < 0 then
                    "Critical Load %" := 0;
                if "Critical Load %" > 100 then
                    "Critical Load %" := 100;
                if "Critical Load %" + "Dampener (% of Total Capacity)" > 100 then
                    "Dampener (% of Total Capacity)" := 100 - "Critical Load %";
            end;
        }
        field(11; "Dampener (% of Total Capacity)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Dampener (% of Total Capacity)';
            DecimalPlaces = 1 : 1;

            trigger OnValidate()
            begin
                if "Dampener (% of Total Capacity)" < 0 then
                    "Dampener (% of Total Capacity)" := 0;
                if "Dampener (% of Total Capacity)" > 100 then
                    "Dampener (% of Total Capacity)" := 100;
                if "Dampener (% of Total Capacity)" + "Critical Load %" > 100 then
                    "Critical Load %" := 100 - "Dampener (% of Total Capacity)";
            end;
        }
        field(14; "Work Center No."; Code[20])
        {
            Caption = 'Work Center No.';
            TableRelation = "Work Center";
        }
        field(39; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(40; "Work Shift Filter"; Code[10])
        {
            Caption = 'Work Shift Filter';
            FieldClass = FlowFilter;
            TableRelation = "Work Shift";
        }
        field(42; "Capacity (Effective)"; Decimal)
        {
            AutoFormatType = 0;
            CalcFormula = sum("Calendar Entry"."Capacity (Effective)" where("Capacity Type" = field("Capacity Type"),
                                                                             "No." = field("Capacity No."),
                                                                             "Work Shift Code" = field("Work Shift Filter"),
                                                                             Date = field("Date Filter")));
            Caption = 'Capacity (Effective)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(44; "Prod. Order Need Qty."; Decimal)
        {
            AutoFormatType = 0;
            CalcFormula = sum("Prod. Order Capacity Need"."Allocated Time" where(Type = field("Capacity Type"),
                                                                                  "No." = field("Capacity No."),
                                                                                  Date = field("Date Filter")));
            Caption = 'Prod. Order Need Qty.';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(46; "Work Center Load Qty."; Decimal)
        {
            AutoFormatType = 0;
            CalcFormula = sum("Prod. Order Capacity Need"."Allocated Time" where("Work Center No." = field("Work Center No."),
                                                                                  Date = field("Date Filter")));
            Caption = 'Work Center Load Qty.';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(48; "Prod. Order Need Qty. for Plan"; Decimal)
        {
            AutoFormatType = 0;
            CalcFormula = sum("Prod. Order Capacity Need"."Allocated Time" where(Type = field("Capacity Type"),
                                                                                  "No." = field("Capacity No."),
                                                                                  Date = field("Date Filter"),
                                                                                  Active = const(true)));
            Caption = 'Prod. Order Need Qty. for Plan';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(49; "Work Center Load Qty. for Plan"; Decimal)
        {
            AutoFormatType = 0;
            CalcFormula = sum("Prod. Order Capacity Need"."Allocated Time" where("Work Center No." = field("Work Center No."),
                                                                                  Date = field("Date Filter"),
                                                                                  Active = const(true)));
            Caption = 'Work Center Load Qty. for Plan';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Capacity Type", "Capacity No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
}

