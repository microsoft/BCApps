namespace Microsoft.CRM.Outlook;
using System.Security.AccessControl;
using System.Utilities;

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

        if not ValidateApprovedGraphDeltaUrl(NewDeltaUrl) then
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

    internal procedure EnforceRecordOwnership()
    begin
        if Session.GetExecutionContext() in [ExecutionContext::Install, ExecutionContext::Upgrade] then
            exit;

        if "User ID" <> CopyStr(UserId(), 1, MaxStrLen("User ID")) then
            Error(CannotModifyOtherUsersSyncErr);
    end;

    internal procedure EnforceRecordOwnershipOnModify(OriginalUserId: Code[50])
    begin
        if Session.GetExecutionContext() in [ExecutionContext::Install, ExecutionContext::Upgrade] then
            exit;

        if "User ID" <> OriginalUserId then
            Error(CannotChangeRecordOwnerErr);

        if OriginalUserId <> CopyStr(UserId(), 1, MaxStrLen("User ID")) then
            Error(CannotModifyOtherUsersSyncErr);
    end;

    internal procedure ValidateApprovedGraphDeltaUrl(DeltaUrlToValidate: Text): Boolean
    var
        Uri: Codeunit Uri;
        IsApproved: Boolean;
    begin
        if DeltaUrlToValidate = '' then
            exit(true);
        IsApproved := Uri.ValidateIntegrationURL(LowerCase(DeltaUrlToValidate), LowerCase(GraphUrlPrefixLbl)) = LowerCase(DeltaUrlToValidate);
        if not IsApproved then
            Session.LogMessage('0000V1Y', StrSubstNo(DeltaUrlValidationTelemetryMsg, DeltaUrlToValidate, IsApproved, InvalidDeltaUrlErr), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', 'Contact Sync');
        exit(IsApproved);
    end;

    var
        DeltaUrlTruncatedTelemetryMsg: Label 'Delta URL was truncated for user Original length: %1', Locked = true, Comment = '%1 = original Delta URL length';
        CannotModifyOtherUsersSyncErr: Label 'You can only modify Contact Sync settings for your own user.';
        CannotChangeRecordOwnerErr: Label 'You cannot change the owner of an existing Contact Sync record.';
        InvalidDeltaUrlErr: Label 'The Delta URL must be an HTTPS Microsoft Graph URL.';
        GraphUrlPrefixLbl: Label 'https://graph.microsoft.com/v1.0/', Locked = true;
        DeltaUrlValidationTelemetryMsg: Label 'Contact Sync delta URL validation. URL: %1; Approved: %2; context : %3', Locked = true, Comment = '%1 = delta URL, %2 = whether URL is approved, %3 = invalid delta url';
}

