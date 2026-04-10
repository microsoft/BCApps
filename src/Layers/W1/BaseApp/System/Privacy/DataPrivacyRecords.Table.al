namespace System.Privacy;

using System.Reflection;

table 1181 "Data Privacy Records"
{
    Access = Public;
    Caption = 'Data Privacy Records';
    DataClassification = CustomerContent;

    fields
    {
        field(1; ID; Integer)
        {
            AutoIncrement = true;
            Caption = 'ID';
            DataClassification = SystemMetadata;
        }
        field(2; "Table No."; Integer)
        {
            Caption = 'Table No.';
            DataClassification = SystemMetadata;
        }
        field(3; "Table Name"; Text[30])
        {
            CalcFormula = lookup(Field.TableName where(TableNo = field("Table No."),
                                                        "No." = field("Field No.")));
            Caption = 'Table Name';
            FieldClass = FlowField;
        }
        field(4; "Field No."; Integer)
        {
            Caption = 'Field No.';
            DataClassification = SystemMetadata;
        }
        field(5; "Field Name"; Text[30])
        {
            CalcFormula = lookup(Field.FieldName where(TableNo = field("Table No."),
                                                        "No." = field("Field No.")));
            Caption = 'Field Name';
            FieldClass = FlowField;
        }
        field(6; "Field DataType"; Text[20])
        {
            Caption = 'Field DataType';
            DataClassification = SystemMetadata;
        }
        field(7; "Field Value"; Text[250])
        {
            Caption = 'Field Value';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; ID)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

