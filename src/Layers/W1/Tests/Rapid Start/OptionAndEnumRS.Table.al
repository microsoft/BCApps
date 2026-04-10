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
            OptionCaptionML = ENU = 'Zero,One,Two', DAN = 'Null,En,To';
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