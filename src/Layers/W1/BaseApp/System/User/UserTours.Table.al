namespace System.Environment.Configuration;

using System.Environment;

table 1314 "User Tours"
{
    Caption = 'User Tours';
    DataPerCompany = false;
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "User ID"; Text[132])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(3; "Tour ID"; Integer)
        {
            Caption = 'Tour ID';
        }
        field(4; Status; Option)
        {
            Caption = 'Status';
            OptionCaption = 'None,Started,Completed,Expired';
            OptionMembers = "None",Started,Completed,Expired;
        }
        field(5; Version; Text[163])
        {
            Caption = 'Version';
        }
    }

    keys
    {
        key(Key1; "User ID", "Tour ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    local procedure GetStatus(TourID: Integer): Integer
    begin
        if not Get(UserId, TourID) then
            exit(Status::None);

        if Version = GetVersion() then
            exit(Status);

        exit(Status::Expired);
    end;

    local procedure SetStatus(TourID: Integer; NewStatus: Option)
    begin
        if not Get(UserId, TourID) then begin
            Init();
            "User ID" := CopyStr(UserId(), 1, MaxStrLen("User ID"));
            "Tour ID" := TourID;
            Insert();
        end;

        Status := NewStatus;
        Version := CopyStr(GetVersion(), 1, MaxStrLen(Version));
        Modify();
    end;

    procedure AlreadyCompleted(TourID: Integer): Boolean
    begin
        exit(GetStatus(TourID) = Status::Completed);
    end;

    procedure MarkAsCompleted(TourID: Integer)
    begin
        SetStatus(TourID, Status::Completed);
    end;

    local procedure GetVersion(): Text
    var
        ApplicationSystemConstants: Codeunit "Application System Constants";
    begin
        exit(StrSubstNo('%1 (%2)', ApplicationSystemConstants.ApplicationVersion(), ApplicationSystemConstants.ApplicationBuild()));
    end;
}

