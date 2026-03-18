namespace System.TestTools.TestRunner;

using System.Reflection;
using System.Security.AccessControl;

table 130405 "CAL Test Result"
{
    Caption = 'CAL Test Result';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'No.';
        }
        field(2; "Test Run No."; Integer)
        {
            Caption = 'Test Run No.';
        }
        field(3; "Codeunit ID"; Integer)
        {
            Caption = 'Codeunit ID';

            trigger OnValidate()
            begin
                SetCodeunitName();
            end;
        }
        field(4; "Codeunit Name"; Text[30])
        {
            Caption = 'Codeunit Name';
        }
        field(5; "Function Name"; Text[128])
        {
            Caption = 'Function Name';
        }
        field(6; Platform; Option)
        {
            Caption = 'Platform';
            OptionCaption = 'Classic,ServiceTier';
            OptionMembers = Classic,ServiceTier;
        }
        field(7; Result; Option)
        {
            Caption = 'Result';
            InitValue = Incomplete;
            OptionCaption = 'Passed,Failed,Inconclusive,Incomplete';
            OptionMembers = Passed,Failed,Inconclusive,Incomplete;
        }
        field(8; Restore; Boolean)
        {
            Caption = 'Restore';
        }
        field(9; "Execution Time"; Duration)
        {
            Caption = 'Execution Time';
        }
        field(10; "Error Code"; Text[250])
        {
            Caption = 'Error Code';
        }
        field(11; "Error Message"; Text[250])
        {
            Caption = 'Error Message';
        }
        field(12; File; Text[250])
        {
            Caption = 'File';
        }
        field(14; "Call Stack"; BLOB)
        {
            Caption = 'Call Stack';
            Compressed = false;
        }
        field(15; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        field(16; "Start Time"; DateTime)
        {
            Caption = 'Start Time';
            Editable = false;
        }
        field(17; "Finish Time"; DateTime)
        {
            Caption = 'Finish Time';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Test Run No.", "Codeunit ID", "Function Name", Platform)
        {
        }
    }

    fieldgroups
    {
    }

    [Scope('OnPrem')]
    procedure Add(SourceCALTestLine: Record "CAL Test Line"; TestRunNo: Integer)
    begin
        Initialize(TestRunNo, SourceCALTestLine."Test Codeunit", SourceCALTestLine."Function", SourceCALTestLine."Start Time");
        Update(SourceCALTestLine.Result = SourceCALTestLine.Result::Success, SourceCALTestLine."Finish Time");
    end;

    procedure Initialize(TestRunNo: Integer; CodeunitId: Integer; FunctionName: Text[128]; StartTime: DateTime): Boolean
    begin
        Init();
        "No." := GetNextNo();
        "Test Run No." := TestRunNo;
        Validate("Codeunit ID", CodeunitId);
        "Function Name" := FunctionName;
        "Start Time" := StartTime;
        "User ID" := UserId();
        Result := Result::Incomplete;
        Platform := Platform::ServiceTier;
        Insert();
    end;

    [Scope('OnPrem')]
    procedure Update(Success: Boolean; FinishTime: DateTime)
    var
        Out: OutStream;
    begin
        if Success then begin
            Result := Result::Passed;
            ClearLastError();
        end else begin
            "Error Code" := CropTo(GetLastErrorCode, 250);
            "Error Message" := CropTo(GetLastErrorText, 250);
            "Call Stack".CreateOutStream(Out);
            Out.WriteText(GetLastErrorCallstack);
            if StrPos("Error Message", 'Known failure:') = 1 then
                Result := Result::Inconclusive
            else
                Result := Result::Failed;
        end;

        "Finish Time" := FinishTime;
        "Execution Time" := "Finish Time" - "Start Time";
        Modify();
    end;

    local procedure GetNextNo(): Integer
    var
        CALTestResult: Record "CAL Test Result";
    begin
        if CALTestResult.FindLast() then
            exit(CALTestResult."No." + 1);
        exit(1);
    end;

    local procedure CropTo(String: Text; Length: Integer): Text[250]
    begin
        if StrLen(String) > Length then
            exit(PadStr(String, Length));
        exit(String);
    end;

    procedure LastTestRunNo(): Integer
    begin
        SetCurrentKey("Test Run No.", "Codeunit ID", "Function Name", Platform);
        if FindLast() then;
        exit("Test Run No.");
    end;

    local procedure SetCodeunitName()
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Codeunit);
        AllObjWithCaption.SetRange("Object ID", "Codeunit ID");
        if AllObjWithCaption.FindFirst() then
            "Codeunit Name" := AllObjWithCaption."Object Name";
    end;
}

