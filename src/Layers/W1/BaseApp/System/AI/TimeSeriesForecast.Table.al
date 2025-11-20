namespace System.AI;

table 2001 "Time Series Forecast"
{
    Caption = 'Time Series Forecast';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Group ID"; Code[50])
        {
            Caption = 'Group ID';
        }
        field(2; "Period No."; Integer)
        {
            Caption = 'Period No.';
        }
        field(3; "Period Start Date"; Date)
        {
            Caption = 'Period Start Date';
        }
        field(4; Value; Decimal)
        {
            Caption = 'Value';
        }
        field(5; Delta; Decimal)
        {
            Caption = 'Delta';
        }
        field(6; "Delta %"; Decimal)
        {
            Caption = 'Delta %';
        }
    }

    keys
    {
        key(Key1; "Group ID", "Period No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

