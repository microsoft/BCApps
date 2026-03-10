namespace Microsoft.CRM.Outlook;
using System.Security.AccessControl;
using System.Security.Encryption;

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
    var
        IsolatedStorageManagement: Codeunit "Isolated Storage Management";
    begin
        if "ID" = 0 then
            exit;

        if NewDeltaUrl = '' then begin
            IsolatedStorageManagement.Delete(GetDeltaUrlStorageKey(), DataScope::Company);
            "Delta Url" := '';
            exit;
        end;

        IsolatedStorageManagement.Set(GetDeltaUrlStorageKey(), CopyStr(NewDeltaUrl, 1, MaxStrLen("Delta Url")), DataScope::Company);
        "Delta Url" := '';
    end;

    procedure GetDeltaUrl(): Text
    var
        IsolatedStorageManagement: Codeunit "Isolated Storage Management";
        DeltaUrlText: Text;
    begin
        if ("ID" <> 0) and IsolatedStorageManagement.Get(GetDeltaUrlStorageKey(), DataScope::Company, DeltaUrlText) then
            exit(CopyStr(DeltaUrlText, 1, MaxStrLen("Delta Url")));

        exit("Delta Url");
    end;

    procedure MigrateDeltaUrlToIsolatedStorage()
    begin
        if ("ID" = 0) or ("Delta Url" = '') then
            exit;

        SetDeltaUrl("Delta Url");
        Modify(false);
    end;

    local procedure GetDeltaUrlStorageKey(): Text
    begin
        exit(CopyStr(DeltaUrlStorageKeyTok + Format("ID"), 1, 200));
    end;

    var
        DeltaUrlStorageKeyTok: Label 'ContactSyncDeltaUrl|', Locked = true;
}