namespace System.AI;

table 852 "Cash Flow Azure AI Buffer"
{
    Caption = 'Cash Flow Azure AI Buffer';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Group Id"; Text[100])
        {
            Caption = 'Group Id';
        }
        field(2; "Period No."; Integer)
        {
            Caption = 'Period No.';
        }
        field(3; Amount; Decimal)
        {
            Caption = 'Amount';
        }
        field(4; Delta; Decimal)
        {
            Caption = 'Delta';
        }
        field(5; "Delta %"; Decimal)
        {
            Caption = 'Delta %';
        }
        field(6; "Period Start"; Date)
        {
            Caption = 'Period Start';
        }
        field(7; "Period Type"; Option)
        {
            Caption = 'Period Type';
            OptionCaption = 'Day,Week,Month,Quarter,Year';
            OptionMembers = Day,Week,Month,Quarter,Year;
        }
        field(8; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'History,Forecast,Correction';
            OptionMembers = History,Forecast,Correction;
        }
    }

    keys
    {
        key(Key1; "Period Start", "Group Id")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

