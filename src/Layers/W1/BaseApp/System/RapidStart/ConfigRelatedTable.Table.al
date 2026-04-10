namespace System.IO;

using System.Reflection;

table 8625 "Config. Related Table"
{
    Caption = 'Config. Related Table';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Table ID"; Integer)
        {
            Caption = 'Table ID';
        }
        field(2; "Relation Table ID"; Integer)
        {
            Caption = 'Relation Table ID';
            Editable = false;
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));
        }
        field(3; "Relation Table Name"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Name" where("Object Type" = const(Table),
                                                                        "Object ID" = field("Relation Table ID")));
            Caption = 'Relation Table Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(4; "Related Fields"; Integer)
        {
            CalcFormula = count("Config. Related Field" where("Table ID" = field("Table ID"),
                                                               "Relation Table ID" = field("Relation Table ID")));
            Caption = 'Related Fields';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5; "In Worksheet"; Boolean)
        {
            BlankZero = true;
            CalcFormula = exist("Config. Line" where("Table ID" = field("Relation Table ID")));
            Caption = 'In Worksheet';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Table ID", "Relation Table ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        ConfigRelatedField: Record "Config. Related Field";
    begin
        ConfigRelatedField.SetRange("Table ID", "Table ID");
        ConfigRelatedField.SetRange("Relation Table ID", "Relation Table ID");
        ConfigRelatedField.DeleteAll();
    end;
}

