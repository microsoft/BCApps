table 135301 "Feature Label Data"
{
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Not Included"; Code[10])
        {
        }
        field(2; "Feature A"; Decimal)
        {
            AutoFormatType = 0;
        }
        field(3; "Feature B"; Option)
        {
            OptionMembers = Option1,Option2,Option3;
        }
        field(4; "Feature C"; Integer)
        {
        }
        field(5; Label; Code[10])
        {
        }
    }

    keys
    {
        key(Key1; "Not Included")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}
