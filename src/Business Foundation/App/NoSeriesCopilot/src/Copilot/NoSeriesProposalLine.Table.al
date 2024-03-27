table 392 "No. Series Proposal Line"
{
    TableType = Temporary;
    fields
    {
        field(1; "Proposal No."; Integer)
        {
            Caption = 'No.';
        }
        field(2; "Series Code"; Code[20])
        {
            Caption = 'Series Code';
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
        field(9; "Setup Table No."; Integer)
        {
            Caption = 'Setup Table No.';
        }
        field(10; "Setup Field No."; Integer)
        {
            Caption = 'Setup Field No.';
        }
    }

    keys
    {
        key(PK; "Proposal No.", "Series Code")
        {
            Clustered = true;
        }
    }
}