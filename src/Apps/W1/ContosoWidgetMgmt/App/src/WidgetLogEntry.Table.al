table 50002 "CWM Widget Log Entry"
{
    Caption = 'Widget Log Entry';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
        }
        field(2; "Widget No."; Code[20])
        {
            Caption = 'Widget No.';
            TableRelation = "CWM Widget"."No.";
        }
        field(3; "Logged At"; DateTime)
        {
            Caption = 'Logged At';
        }
        field(4; Status; Option)
        {
            Caption = 'Status';
            OptionMembers = Success,Failure;
        }
        field(5; Message; Text[250])
        {
            Caption = 'Message';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }
}
