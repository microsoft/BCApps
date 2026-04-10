#pragma warning disable AA0247
table 26571 "Page Indication XML Element"
{
    Caption = 'Page Indication XML Element';
    LookupPageID = "Page Indication XML Elements";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Report Code"; Code[20])
        {
            Caption = 'Report Code';
            TableRelation = "Statutory Report";
        }
        field(2; "Table Code"; Code[20])
        {
            Caption = 'Table Code';
            TableRelation = "Statutory Report Table".Code where("Report Code" = field("Report Code"));
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; "XML Element Line No."; Integer)
        {
            Caption = 'XML Element Line No.';
        }
        field(5; "XML Element Name"; Text[30])
        {
            Caption = 'XML Element Name';
        }
    }

    keys
    {
        key(Key1; "Report Code", "Table Code", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

