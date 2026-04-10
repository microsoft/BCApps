table 132591 "All-Keys Type"
{
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; Key1; Integer)
        {
        }
        field(2; Key2; Code[10])
        {
        }
        field(3; Key3; Option)
        {
            OptionMembers = First,Second,Third;
        }
    }

    keys
    {
        key(Key1; Key1, Key2, Key3)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    [Scope('OnPrem')]
    procedure Create(NewKey1: Integer; NewKey2: Code[10]; NewKey3: Option)
    begin
        Key1 := NewKey1;
        Key2 := NewKey2;
        Key3 := NewKey3;
        Insert();
    end;
}

