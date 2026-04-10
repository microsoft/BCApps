namespace System.Automation;

table 468 "Workflow Webhook Notification"
{
    Caption = 'Workflow Webhook Notification';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Notification No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'Notification No.';
        }
        field(2; "Workflow Step Instance ID"; Guid)
        {
            Caption = 'Workflow Step Instance ID';
        }
        field(3; "Date-Time Created"; DateTime)
        {
            Caption = 'Date-Time Created';
        }
        field(4; "Created By User ID"; Code[50])
        {
            Caption = 'Created By User ID';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(5; Status; Option)
        {
            Caption = 'Status';
            OptionCaption = 'Pending,Sent,Failed';
            OptionMembers = Pending,Sent,Failed;
        }
        field(6; "Error Message"; Text[250])
        {
            Caption = 'Error Message';
        }
        field(7; "Error Details"; BLOB)
        {
            Caption = 'Error Details';
        }
    }

    keys
    {
        key(Key1; "Notification No.")
        {
            Clustered = true;
        }
        key(Key2; "Workflow Step Instance ID")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        "Date-Time Created" := CreateDateTime(Today, Time);
        "Created By User ID" := UserId;
    end;

    procedure GetErrorDetails(): Text
    var
        ReadStream: InStream;
        ReturnText: Text;
    begin
        CalcFields("Error Details");
        "Error Details".CreateInStream(ReadStream);
        ReadStream.ReadText(ReturnText);
        exit(ReturnText);
    end;

    procedure SetErrorDetails(ErrorDetails: Text)
    var
        OutStream: OutStream;
    begin
        "Error Details".CreateOutStream(OutStream);
        OutStream.Write(ErrorDetails);
    end;

    procedure SetErrorMessage(ErrorMessage: Text)
    begin
        if StrLen(ErrorMessage) > 250 then
            "Error Message" := PadStr(ErrorMessage, 250)
        else
            "Error Message" := CopyStr(ErrorMessage, 1, StrLen(ErrorMessage));
    end;
}

