table 134449 "County Caption Test"
{
    DataClassification = CustomerContent;
    ReplicateData = false;

    fields
    {
        field(1; "Entry No."; Integer)
        {
        }
        field(9; County; Text[30])
        {
            CaptionClass = '5,1,' + "Country/Region Code";
            Caption = 'County';
        }
        field(14; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
    }
}