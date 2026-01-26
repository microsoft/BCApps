table 160801 "Acc. Schedules Conversion"
{
    Caption = 'Acc. Schedules Conversion';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Schedule Name"; Code[10])
        {
            Caption = 'Schedule Name';
            TableRelation = "Acc. Schedule Line"."Schedule Name";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            TableRelation = "Acc. Schedule Line"."Line No." where("Schedule Name" = field("Schedule Name"));
        }
        field(3; "Totaling (Old)"; Text[80])
        {
            CalcFormula = lookup("Acc. Schedule Line".Totaling where("Schedule Name" = field("Schedule Name"),
                                                                      "Line No." = field("Line No.")));
            Caption = 'Totaling (Old)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(4; "Totaling (New)"; Text[80])
        {
            Caption = 'Totaling (New)';
        }
        field(5; "Row No."; Code[10])
        {
            CalcFormula = lookup("Acc. Schedule Line"."Row No." where("Schedule Name" = field("Schedule Name"),
                                                                       "Line No." = field("Line No.")));
            Caption = 'Row No.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(6; Description; Text[80])
        {
            CalcFormula = lookup("Acc. Schedule Line".Description where("Schedule Name" = field("Schedule Name"),
                                                                         "Line No." = field("Line No.")));
            Caption = 'Description';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Schedule Name", "Line No.")
        {
        }
    }

    fieldgroups
    {
    }
}

