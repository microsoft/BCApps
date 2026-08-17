table 130202 "Test Result"
{
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Integer)
        {
            AutoIncrement = true;
        }
        field(2; "Test Run No."; Integer)
        {
        }
        field(3; CUId; Integer)
        {
        }
        field(4; CUName; Text[30])
        {
        }
        field(5; FName; Text[128])
        {
        }
        field(6; Platform; Option)
        {
            OptionMembers = Classic,ServiceTier;
        }
        field(7; Result; Option)
        {
            InitValue = Incomplete;
            OptionMembers = Passed,Failed,Inconclusive,Incomplete;
        }
        field(8; Restore; Boolean)
        {
        }
        field(9; "Execution Time"; Duration)
        {
        }
        field(10; "Error Code"; Text[2048])
        {
        }
        field(11; "Error Message"; Text[2048])
        {
        }
        field(12; File; Text[250])
        {
        }
        field(13; Database; Text[250])
        {
        }
        field(14; "Call Stack"; BLOB)
        {
            Compressed = false;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Test Run No.", CUId, FName, Platform)
        {
        }
    }

    fieldgroups
    {
    }

    var
        BackupMgt: Codeunit "Backup Management";

    [Scope('OnPrem')]
    procedure Create(TestRunNo: Integer; CodId: Integer; CodName: Text[30]; FuncName: Text[128]): Boolean
    var
        TestCodeunit: Record "Test Codeunit";
        TestResult: Record "Test Result";
        NextNo: Integer;
    begin
        NextNo := 1;
        if TestResult.FindLast() then
            NextNo := TestResult."No." + 1;

        Init();

        "No." := NextNo;
        "Test Run No." := TestRunNo;
        CUId := CodId;
        CUName := CodName;
        FName := FuncName;

        Platform := Platform::ServiceTier;

        if TestCodeunit.Get(CodId) then
            File := TestCodeunit.File;

        Database := BackupMgt.GetDatabase();

        Insert();
    end;

    [Scope('OnPrem')]
    procedure Update(Success: Boolean; Duration: Duration; IsRestored: Boolean)
    var
        Out: OutStream;
    begin
        if Success then begin
            Result := Result::Passed;
            ClearLastError();
        end
        else begin
            if StrPos(GetLastErrorText, 'Known failure: see VSTF Bug #') = 1 then
                Result := Result::Inconclusive
            else
                Result := Result::Failed;
            "Error Code" := CropTo(GetLastErrorCode, MaxStrLen("Error Code"));
            "Error Message" := CropTo(GetLastErrorText, MaxStrLen("Error Message"));
            "Call Stack".CreateOutStream(Out);
            Out.WriteText(GetLastErrorCallstack);
        end;

        "Execution Time" := Duration;
        Restore := IsRestored;
        Modify();
    end;

    [Scope('OnPrem')]
    procedure LastTestRunNo(): Integer
    begin
        SetCurrentKey("Test Run No.", CUId, FName, Platform);
        if FindLast() then;
        exit("Test Run No.")
    end;

    local procedure CropTo(String: Text; Length: Integer): Text
    begin
        if StrLen(String) > Length then
            exit(PadStr(String, Length));
        exit(String)
    end;
}

