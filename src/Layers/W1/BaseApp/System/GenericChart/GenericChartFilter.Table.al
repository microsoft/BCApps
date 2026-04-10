namespace System.Visualization;

table 9181 "Generic Chart Filter"
{
    Caption = 'Generic Chart Filter';
    DataClassification = CustomerContent;

    fields
    {
        field(2; ID; Code[20])
        {
            Caption = 'ID';
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(10; "Filter Field ID"; Integer)
        {
            Caption = 'Filter Field ID';
        }
        field(11; "Filter Field Name"; Text[30])
        {
            Caption = 'Filter Field Name';
        }
        field(15; "Filter Value"; Text[250])
        {
            Caption = 'Filter Value';
        }
    }

    keys
    {
        key(Key1; ID, "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

