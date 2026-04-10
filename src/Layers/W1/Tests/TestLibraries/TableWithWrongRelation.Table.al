table 132515 "Table With Wrong Relation"
{
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Integer)
        {
        }
        field(2; WrongType; DateTime)
        {
            TableRelation = User."User Name";
            ValidateTableRelation = false;
        }
        field(3; WrongLength; Code[5])
        {
            TableRelation = User."User Name";
            ValidateTableRelation = false;
        }
    }

    keys
    {
        key(Key1; Id)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

