table 130642 "Webhook Notification Trigger"
{
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; ID; Guid)
        {
        }
        field(2; ContactID; Text[250])
        {
        }
        field(3; ChangeType; Text[50])
        {
        }
        field(4; TaskID; Guid)
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

    trigger OnInsert()
    begin
        if IsNullGuid(ID) then
            ID := CreateGuid();
    end;
}

