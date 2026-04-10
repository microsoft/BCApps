table 132450 "Job Queue Sample Logging"
{
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Integer)
        {
            Description = 'Unique Row Identifier';
            InitValue = 0;
            NotBlank = true;
        }
        field(2; "User ID"; Text[30])
        {
            Description = 'User who logged the record';
        }
        field(3; "Session ID"; Integer)
        {
            Description = 'Service ID which logged the record';
        }
        field(4; MessageToLog; Text[250])
        {
            Description = 'Message logged';
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    [Scope('OnPrem')]
    procedure LogRecord(Msg: Text[100])
    var
        nextKey: Integer;
    begin
        LockTable();
        if FindLast() then
            nextKey := "No." + 1;

        Init();
        "No." := nextKey;
        "User ID" := UserId;
        "Session ID" := ServiceInstanceId();
        MessageToLog := '[' + Format(DT2Time(CurrentDateTime), 0, '<Hours24>:<Minutes>:<Seconds>.<Thousands>') + '] ' + Msg;

        Insert();
        Commit();
    end;
}

