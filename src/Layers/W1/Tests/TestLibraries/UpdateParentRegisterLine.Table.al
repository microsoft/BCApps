table 139143 "Update Parent Register Line"
{
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; ID; Code[10])
        {
        }
        field(2; Sequence; Integer)
        {
        }
        field(3; "Page Id"; Integer)
        {
        }
        field(4; Method; Option)
        {
            OptionMembers = Validate,Insert,Modify,Delete,AfterGetCurrRecord,AfterGetRecord;
        }
        field(5; Operation; Option)
        {
            OptionMembers = Visit,PreUpdate,PostUpdate;
        }
    }

    keys
    {
        key(Key1; ID, Sequence)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

