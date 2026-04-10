namespace System.Automation;

using System.Reflection;

table 1505 "Workflow - Table Relation"
{
    Caption = 'Workflow - Table Relation';
    ReplicateData = true;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));
        }
        field(2; "Field ID"; Integer)
        {
            Caption = 'Field ID';
            TableRelation = Field."No." where(TableNo = field("Table ID"));
        }
        field(3; "Related Table ID"; Integer)
        {
            Caption = 'Related Table ID';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));
        }
        field(4; "Related Field ID"; Integer)
        {
            Caption = 'Related Field ID';
            TableRelation = Field."No." where(TableNo = field("Related Table ID"));
        }
        field(5; "Table Caption"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Table),
                                                                           "Object ID" = field("Table ID")));
            Caption = 'Table Caption';
            Editable = false;
            FieldClass = FlowField;
        }
        field(6; "Field Caption"; Text[250])
        {
            CalcFormula = lookup(Field."Field Caption" where(TableNo = field("Table ID"),
                                                              "No." = field("Field ID")));
            Caption = 'Field Caption';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7; "Related Table Caption"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Table),
                                                                           "Object ID" = field("Related Table ID")));
            Caption = 'Related Table Caption';
            Editable = false;
            FieldClass = FlowField;
        }
        field(8; "Related Field Caption"; Text[250])
        {
            CalcFormula = lookup(Field."Field Caption" where(TableNo = field("Related Table ID"),
                                                              "No." = field("Related Field ID")));
            Caption = 'Related Field Caption';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Table ID", "Field ID", "Related Table ID", "Related Field ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

