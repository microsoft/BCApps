table 392 "No. Series Proposal Entry Line"
{
    TableType = Temporary;
    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Generation Id';
        }
        field(2; "Series Code"; Code[20])
        {
            Caption = 'Series Code';
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }

        field(4; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(5; "Starting No."; Code[20])
        {
            Caption = 'Starting No.';
        }
        field(6; "Ending No."; Code[20])
        {
            Caption = 'Ending No.';
        }
        field(7; "Warning No."; Code[20])
        {
            Caption = 'Warning No.';
        }
        field(8; "Increment-by No."; Integer)
        {
            Caption = 'Increment-by No.';
        }
    }

    keys
    {
        key(PK; "Entry No.", "Series Code", "Line No.")
        {
            Clustered = true;
        }
    }
}