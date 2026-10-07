#pragma warning disable AA0247
table 14932 "Excel Template Sheet Buffer"
{
    Caption = 'Excel Template Sheet Buffer';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Sheet Name"; Text[31])
        {
            Caption = 'Sheet Name';
            DataClassification = SystemMetadata;
        }
        field(2; "Paper Height"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Paper Height';
            DataClassification = SystemMetadata;
        }
        field(4; "Current Paper Height"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Current Paper Height';
            DataClassification = SystemMetadata;
        }
        field(5; "Last Page No."; Integer)
        {
            Caption = 'Last Page No.';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Sheet Name")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

