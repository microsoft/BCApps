table 130205 "Test Runner Argument"
{
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; Switch; Text[128])
        {
        }
        field(2; Value; Text[250])
        {
        }
    }

    keys
    {
        key(Key1; Switch)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    [Scope('OnPrem')]
    procedure TryGet(Switch: Text[128]): Text[250]
    begin
        if Get(Switch) then
            exit(Value);
        exit('')
    end;
}

