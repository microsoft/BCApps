table 130203 "Enabled Test Method"
{
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Test Codeunit ID"; Integer)
        {
        }
        field(2; "Test Method Name"; Text[128])
        {
        }
    }

    keys
    {
        key(Key1; "Test Codeunit ID", "Test Method Name")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    [Scope('OnPrem')]
    procedure InsertEntry(CodeunitID: Integer; FunctionName: Text[128])
    begin
        Init();

        Validate("Test Codeunit ID", CodeunitID);
        Validate("Test Method Name", FunctionName);
        Insert(true);
    end;
}

