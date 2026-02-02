table 6800 "Media Types"
{
    Caption = 'Media Types';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; Mandate; Text[40])
        {
            Caption = 'Mandate';
        }
        field(2; "Invoice Available Media Types"; Text[256])
        {
            Caption = 'Invoice Available Media Types';
        }
    }
    keys
    {
        key(PK; Mandate)
        {
            Clustered = true;
        }
    }
}
