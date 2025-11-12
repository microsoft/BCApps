namespace System.Visualization;

table 450 "Bar Chart Buffer"
{
    Caption = 'Bar Chart Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Series No."; Integer)
        {
            Caption = 'Series No.';
            DataClassification = SystemMetadata;
        }
        field(2; "Column No."; Integer)
        {
            Caption = 'Column No.';
            DataClassification = SystemMetadata;
        }
        field(3; "Y Value"; Decimal)
        {
            Caption = 'Y Value';
            DataClassification = SystemMetadata;
        }
        field(4; "X Value"; Text[100])
        {
            Caption = 'X Value';
            DataClassification = SystemMetadata;
        }
        field(5; Tag; Text[250])
        {
            Caption = 'Tag';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Series No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

