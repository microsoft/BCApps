// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.WorkCenter;

using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Setup;

table 99000756 "Work Center Group"
{
    Caption = 'Work Center Group';
    DataCaptionFields = "Code", Name;
    DrillDownPageID = "Work Center Groups";
    LookupPageID = "Work Center Groups";
    Permissions = TableData "Prod. Order Capacity Need" = r;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Name; Text[50])
        {
            Caption = 'Name';
        }
        field(20; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(21; "Work Shift Filter"; Code[10])
        {
            Caption = 'Work Shift Filter';
            FieldClass = FlowFilter;
            TableRelation = "Work Shift";
        }
        field(22; "Capacity (Total)"; Decimal)
        {
            CalcFormula = sum("Calendar Entry"."Capacity (Total)" where("Capacity Type" = const("Work Center"),
                                                                         "Work Center Group Code" = field(Code),
                                                                         "Work Shift Code" = field("Work Shift Filter"),
                                                                         Date = field("Date Filter")));
            Caption = 'Capacity (Total)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(23; "Capacity (Effective)"; Decimal)
        {
            CalcFormula = sum("Calendar Entry"."Capacity (Effective)" where("Capacity Type" = const("Work Center"),
                                                                             "Work Center Group Code" = field(Code),
                                                                             "Work Shift Code" = field("Work Shift Filter"),
                                                                             Date = field("Date Filter")));
            Caption = 'Capacity (Effective)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(24; "Prod. Order Need (Qty.)"; Decimal)
        {
            CalcFormula = sum("Prod. Order Capacity Need"."Allocated Time" where(Status = field("Prod. Order Status Filter"),
                                                                                  "Work Center Group Code" = field(Code),
                                                                                  Date = field("Date Filter"),
                                                                                  "Requested Only" = const(false)));
            Caption = 'Prod. Order Need (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(47; "Prod. Order Status Filter"; Enum "Production Order Status")
        {
            Caption = 'Prod. Order Status Filter';
            FieldClass = FlowFilter;
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
}

