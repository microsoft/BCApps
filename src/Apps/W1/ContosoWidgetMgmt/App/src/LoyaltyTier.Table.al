// Own object deliberately declared without the app's mandatory affix (CWM).
// Any other app that also defines a "Loyalty Tier" table collides with this one.
table 50003 "Loyalty Tier"
{
    Caption = 'Loyalty Tier';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
        }
        field(10; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(20; "Minimum Points"; Integer)
        {
            Caption = 'Minimum Points';
        }
    }

    keys
    {
        key(PK; "Code")
        {
            Clustered = true;
        }
    }
}
