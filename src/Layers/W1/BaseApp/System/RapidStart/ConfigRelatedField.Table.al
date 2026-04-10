namespace System.IO;

using System.Reflection;

table 8624 "Config. Related Field"
{
    Caption = 'Config. Related Field';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Table ID"; Integer)
        {
            Caption = 'Table ID';
        }
        field(2; "Field ID"; Integer)
        {
            Caption = 'Field ID';
        }
        field(3; "Field Name"; Text[30])
        {
            CalcFormula = lookup (Field.FieldName where(TableNo = field("Table ID"),
                                                        "No." = field("Field ID")));
            Caption = 'Field Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(4; "Field Caption"; Text[250])
        {
            CalcFormula = lookup (Field."Field Caption" where(TableNo = field("Table ID"),
                                                              "No." = field("Field ID")));
            Caption = 'Field Caption';
            Editable = false;
            FieldClass = FlowField;
        }
        field(8; "Relation Table ID"; Integer)
        {
            Caption = 'Relation Table ID';
            Editable = false;
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));
        }
        field(9; "Relation Table Name"; Text[250])
        {
            CalcFormula = lookup (AllObjWithCaption."Object Name" where("Object Type" = const(Table),
                                                                        "Object ID" = field("Relation Table ID")));
            Caption = 'Relation Table Name';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Table ID", "Field ID")
        {
            Clustered = true;
        }
        key(Key2; "Table ID", "Relation Table ID")
        {
        }
    }

    fieldgroups
    {
    }
}

