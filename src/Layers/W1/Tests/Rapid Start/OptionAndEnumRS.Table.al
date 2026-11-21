table 136605 OptionAndEnumRS
{
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; PK; Integer)
        {
        }
        field(5; OptionField; Option)
        {
            OptionMembers = Zero,One,Two;
            OptionCaption = 'Zero,One,Two';
        }
        field(10; EnumField; Enum EnumRs)
        {
        }
    }

    keys
    {
        key(PK; PK)
        {
            Clustered = true;
        }
    }
}