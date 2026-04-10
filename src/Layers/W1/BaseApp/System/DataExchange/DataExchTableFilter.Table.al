namespace System.IO;

table 1233 "Data Exch. Table Filter"
{
    Caption = 'Data Exch. Table Filter';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Data Exch. No."; Integer)
        {
            Caption = 'Data Exch. No.';
            TableRelation = "Data Exch.";
        }
        field(2; "Table ID"; Integer)
        {
            Caption = 'Table ID';
        }
        field(3; "Table Filters"; BLOB)
        {
            Caption = 'Table Filters';
        }
    }

    keys
    {
        key(PK; "Data Exch. No.", "Table ID")
        {
            Clustered = true;
        }
    }
}
