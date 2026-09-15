#pragma warning disable AA0247
table 14903 "Agreement Group"
{
    Caption = 'Agreement Group';
    LookupPageID = "Agreement Groups";
    DataClassification = CustomerContent;

    fields
    {
        field(1; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Sales,Purchases';
            OptionMembers = Sales,Purchases;
        }
        field(2; "Code"; Code[20])
        {
            Caption = 'Code';
        }
        field(3; Description; Text[50])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; Type, "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

