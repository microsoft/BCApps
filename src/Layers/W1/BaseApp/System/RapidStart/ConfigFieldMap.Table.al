namespace System.IO;

using System.Reflection;

table 8629 "Config. Field Map"
{
    Caption = 'Config. Field Mapping';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Package Code"; Code[20])
        {
            Caption = 'Package Code';
            NotBlank = true;
            TableRelation = "Config. Package";
        }
        field(2; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            NotBlank = true;
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));
        }
        field(3; "Field ID"; Integer)
        {
            Caption = 'Field ID';
            NotBlank = true;
        }
        field(4; "Field Name"; Text[30])
        {
            Caption = 'Field Name';
        }
        field(5; "Old Value"; Text[2048])
        {
            Caption = 'Old Value';
        }
        field(6; "New Value"; Text[2048])
        {
            Caption = 'New Value';
        }
        field(7; ID; BigInteger)
        {
            Caption = 'ID';
            AutoIncrement = true;
        }
    }

    keys
    {
        key(Key1; ID)
        {
            Clustered = true;
        }
        key(Key2; "Package Code", "Table ID", "Field ID", "Old Value")
        {
            Unique = true;
        }
    }
}

