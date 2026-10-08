table 140000 "Data Type Buffer NA"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; ID; Integer)
        {
        }
        field(2; BLOB; BLOB)
        {
        }
        field(3; BigInteger; BigInteger)
        {
        }
        field(5; Boolean; Boolean)
        {
        }
        field(6; "Code"; Code[10])
        {
        }
        field(7; Date; Date)
        {
        }
        field(8; DateFormula; DateFormula)
        {
        }
        field(9; DateTime; DateTime)
        {
        }
        field(10; Decimal; Decimal)
        {
            AutoFormatType = 0;
        }
        field(11; Duration; Duration)
        {
        }
        field(12; GUID; Guid)
        {
        }
        field(13; Option; Option)
        {
            OptionMembers = ,option1,option2;
        }
        field(14; RecordID; RecordID)
        {
        }
        field(16; Text; Text[30])
        {
        }
        field(17; Time; Time)
        {
        }
    }

    keys
    {
        key(Key1; ID)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}
