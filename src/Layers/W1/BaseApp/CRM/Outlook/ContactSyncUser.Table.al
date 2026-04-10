namespace Microsoft.CRM.Outlook;
using System.Security.AccessControl;

table 7121 "Contact Sync User"
{
    Caption = 'Contact Sync User';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "ID"; Integer)
        {
            Caption = 'ID';
            DataClassification = SystemMetadata;
            AutoIncrement = true;
        }
        field(2; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            NotBlank = true;
            TableRelation = User."User Name";
            ValidateTableRelation = false;
        }
        field(3; "Last Sync Date Time"; DateTime)
        {
            Caption = 'Last Sync Date Time';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(4; "Folder ID"; Text[250])
        {
            DataClassification = SystemMetadata;
            Caption = 'Folder ID';
        }
        field(5; "Delta Url"; Text[2048])
        {
            DataClassification = SystemMetadata;
            Caption = 'Delta URL';
        }
        field(6; "Folder Name"; Text[250])
        {
            DataClassification = SystemMetadata;
            Caption = 'Folder Name';
        }
    }

    keys
    {
        key(PK; "ID")
        {
            Clustered = true;
        }
        key(UserFolder; "User ID", "Folder ID")
        {
        }
        key(FolderEmail; "Folder ID")
        {
        }
        key(UserFolderSync; "User ID", "Folder ID", "Last Sync Date Time")
        {
        }
    }

    procedure SetDeltaUrl(NewDeltaUrl: Text)
    begin
        if "ID" = 0 then
            exit;

        "Delta Url" := CopyStr(NewDeltaUrl, 1, MaxStrLen("Delta Url"));
        if StrLen(NewDeltaUrl) > MaxStrLen("Delta Url") then
            Session.LogMessage('0000SET', StrSubstNo(DeltaUrlTruncatedTelemetryMsg, StrLen(NewDeltaUrl)), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', 'Contact Sync');
        Modify();
    end;

    procedure GetDeltaUrl(): Text
    begin
        exit("Delta Url");
    end;

    var
        DeltaUrlTruncatedTelemetryMsg: Label 'Delta URL was truncated for user Original length: %1', Locked = true, Comment = '%1 = original Delta URL length';
}