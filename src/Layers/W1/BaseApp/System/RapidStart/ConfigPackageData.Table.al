namespace System.IO;

using System.Reflection;

table 8615 "Config. Package Data"
{
    Caption = 'Config. Package Data';
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
        field(3; "No."; Integer)
        {
            Caption = 'No.';
            TableRelation = "Config. Package Record"."No." where("Package Code" = field("Package Code"),
                                                                 "Table ID" = field("Table ID"));
        }
        field(4; "Field ID"; Integer)
        {
            Caption = 'Field ID';
            TableRelation = "Config. Package Field"."Field ID" where("Package Code" = field("Package Code"),
                                                                     "Table ID" = field("Table ID"));
        }
        field(5; Value; Text[2048])
        {
            Caption = 'Value';
        }
        field(6; Invalid; Boolean)
        {
            Caption = 'Invalid';
        }
        field(7; "BLOB Value"; BLOB)
        {
            Caption = 'BLOB Value';
        }
    }

    keys
    {
        key(Key1; "Package Code", "Table ID", "No.", "Field ID")
        {
            Clustered = true;
        }
        key(Key2; "Package Code", "Table ID", "Field ID")
        {
        }
    }

    fieldgroups
    {
    }
}
