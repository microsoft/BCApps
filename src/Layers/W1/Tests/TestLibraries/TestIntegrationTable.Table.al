table 139165 "Test Integration Table"
{
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(2; "Integration Field Value"; Text[10])
        {
            Description = 'UOM Description';
        }
        field(3; "Integration Slave Field Value"; Code[10])
        {
            Description = 'UOM International Standard Code';
        }
        field(10; "Integration Uid"; Guid)
        {
        }
        field(11; "Integration Modified Field"; DateTime)
        {
        }
        field(12; ModifiedBy; Guid)
        {
        }
    }

    keys
    {
        key(Key1; "Integration Uid")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

