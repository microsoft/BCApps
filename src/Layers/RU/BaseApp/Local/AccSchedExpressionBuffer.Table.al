#pragma warning disable AA0247
table 26585 "Acc. Sched. Expression Buffer"
{
    Caption = 'Acc. Sched. Expression Buffer';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }
        field(2; Totaling; Text[250])
        {
            Caption = 'Totaling';
            DataClassification = SystemMetadata;
        }
        field(3; Amount; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Amount';
            DataClassification = SystemMetadata;
        }
        field(4; "Row No."; Code[20])
        {
            Caption = 'Row No.';
            DataClassification = SystemMetadata;
        }
        field(5; "Totaling Type"; Enum "Acc. Schedule Line Totaling Type")
        {
            Caption = 'Totaling Type';
            DataClassification = SystemMetadata;
        }
        field(6; Description; Text[250])
        {
            CalcFormula = lookup("Acc. Schedule Line".Description where("Schedule Name" = field("Schedule Name"),
                                                                         "Line No." = field("Acc. Schedule Line No.")));
            Caption = 'Description';
            FieldClass = FlowField;
        }
        field(10; "Schedule Name"; Code[10])
        {
            Caption = 'Schedule Name';
            DataClassification = SystemMetadata;
            TableRelation = "Acc. Schedule Name";
        }
        field(11; "Acc. Schedule Line No."; Integer)
        {
            Caption = 'Acc. Schedule Line No.';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

