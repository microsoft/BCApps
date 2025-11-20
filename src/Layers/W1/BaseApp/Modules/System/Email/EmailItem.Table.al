namespace System.Email;

#if not CLEAN27
using System.IO;
#endif
using System.Utilities;

table 9500 "Email Item"
{
    Caption = 'Email Item';
    DataClassification = CustomerContent;

    fields
    {
        field(1; ID; Guid)
        {
            Caption = 'ID';
        }
        field(2; "From Name"; Text[100])
        {
            Caption = 'From Name';
        }
        field(3; "From Address"; Text[250])
        {
            Caption = 'From Address';

            trigger OnValidate()
            var
                MailManagement: Codeunit "Mail Management";
            begin
                if "From Address" <> '' then
                    MailManagement.CheckValidEmailAddresses("From Address");
            end;
        }
        field(4; "Send to"; Text[250])
        {
            Caption = 'Send to';

            trigger OnValidate()
            begin
                if "Send to" <> '' then
                    CorrectAndValidateEmailList("Send to");
            end;
        }
        field(5; "Send CC"; Text[250])
        {
            Caption = 'Send CC';

            trigger OnValidate()
            begin
                if "Send CC" <> '' then
                    CorrectAndValidateEmailList("Send CC");
            end;
        }
        field(6; "Send BCC"; Text[250])
        {
            Caption = 'Send BCC';

            trigger OnValidate()
            begin
                if "Send BCC" <> '' then
                    CorrectAndValidateEmailList("Send BCC");
            end;
        }
        field(7; Subject; Text[250])
        {
            Caption = 'Subject';
        }
        field(8; Body; BLOB)
        {
            Caption = 'Body';
        }
#if not CLEANSCHEMA28
        field(9; "Attachment File Path"; Text[250])
        {
            Caption = 'Attachment File Path';
            ObsoleteReason = 'Replaced with method AddAttachment that accepts Streams.';
#if CLEAN25
            ObsoleteState = Removed;
            ObsoleteTag = '28.0';
#else
            ObsoleteState = Pending;
            ObsoleteTag = '17.2';
#endif
        }
        field(10; "Attachment Name"; Text[250])
        {
            Caption = 'Attachment Name';
            ObsoleteReason = 'Replaced with method AddAttachment that accepts Streams.';
#if CLEAN25
            ObsoleteState = Removed;
            ObsoleteTag = '28.0';
#else
            ObsoleteState = Pending;
            ObsoleteTag = '17.2';
#endif
        }
#endif
        field(11; "Plaintext Formatted"; Boolean)
        {
            Caption = 'Plaintext Formatted';
            InitValue = true;

            trigger OnValidate()
            begin
#if not CLEAN27
                if "Plaintext Formatted" then
#pragma warning disable AL0432
                    Validate("Body File Path", '')
#pragma warning restore AL0432
                else
                    SetBodyText('');
#else
                Clear(Body);
#endif
            end;
        }
#if not CLEANSCHEMA30
        field(12; "Body File Path"; Text[250])
        {
            Caption = 'Body File Path';
            ObsoleteReason = 'Replaced with field Body. You can use the new procedure SetBody to update the value of the html formatted body.';
#if CLEAN27
            ObsoleteState = Removed;
            ObsoleteTag = '30.0';
#else
            ObsoleteState = Pending;
            ObsoleteTag = '27.0';
#endif
#if not CLEAN27
            trigger OnValidate()
            begin
                if "Body File Path" <> '' then
                    TestField("Plaintext Formatted", false);
            end;
#endif
        }
#endif
        field(13; "Message Type"; Option)
        {
            Caption = 'Message Type';
            OptionCaption = 'Custom Message,From Email Body Template';
            OptionMembers = "Custom Message","From Email Body Template";
        }
        field(14; "Send as HTML"; Boolean)
        {
            Caption = 'Send as HTML';
            InitValue = true;
        }
#if not CLEANSCHEMA28
        field(21; "Attachment File Path 2"; Text[250])
        {
            Caption = 'Attachment File Path 2';
            ObsoleteReason = 'Replaced with method AddAttachment that accepts Streams.';
#if CLEAN25
            ObsoleteState = Removed;
            ObsoleteTag = '28.0';
#else
            ObsoleteState = Pending;
            ObsoleteTag = '17.2';
#endif
        }
        field(22; "Attachment Name 2"; Text[50])
        {
            Caption = 'Attachment Name 2';
            ObsoleteReason = 'Replaced with method AddAttachment that accepts Streams.';
#if CLEAN25
            ObsoleteState = Removed;
            ObsoleteTag = '28.0';
#else
            ObsoleteState = Pending;
            ObsoleteTag = '17.2';
#endif
        }
        field(23; "Attachment File Path 3"; Text[250])
        {
            Caption = 'Attachment File Path 3';
            ObsoleteReason = 'Replaced with method AddAttachment that accepts Streams.';
#if CLEAN25
            ObsoleteState = Removed;
            ObsoleteTag = '28.0';
#else
            ObsoleteState = Pending;
            ObsoleteTag = '17.2';
#endif
        }
        field(24; "Attachment Name 3"; Text[50])
        {
            Caption = 'Attachment Name 3';
            ObsoleteReason = 'Replaced with method AddAttachment that accepts Streams.';
#if CLEAN25
            ObsoleteState = Removed;
            ObsoleteTag = '28.0';
#else
            ObsoleteState = Pending;
            ObsoleteTag = '17.2';
#endif
        }
        field(25; "Attachment File Path 4"; Text[250])
        {
            Caption = 'Attachment File Path 4';
            ObsoleteReason = 'Replaced with method AddAttachment that accepts Streams.';
#if CLEAN25
            ObsoleteState = Removed;
            ObsoleteTag = '28.0';
#else
            ObsoleteState = Pending;
            ObsoleteTag = '17.2';
#endif
        }
        field(26; "Attachment Name 4"; Text[50])
        {
            Caption = 'Attachment Name 4';
            ObsoleteReason = 'Replaced with method AddAttachment that accepts Streams.';
#if CLEAN25
            ObsoleteState = Removed;
            ObsoleteTag = '28.0';
#else
            ObsoleteState = Pending;
            ObsoleteTag = '17.2';
#endif
        }
        field(27; "Attachment File Path 5"; Text[250])
        {
            Caption = 'Attachment File Path 5';
            ObsoleteReason = 'Replaced with method AddAttachment that accepts Streams.';
#if CLEAN25
            ObsoleteState = Removed;
            ObsoleteTag = '28.0';
#else
            ObsoleteState = Pending;
            ObsoleteTag = '17.2';
#endif
        }
        field(28; "Attachment Name 5"; Text[50])
        {
            Caption = 'Attachment Name 5';
            ObsoleteReason = 'Replaced with method AddAttachment that accepts Streams.';
#if CLEAN25
            ObsoleteState = Removed;
            ObsoleteTag = '28.0';
#else
            ObsoleteState = Pending;
            ObsoleteTag = '17.2';
#endif
        }
        field(29; "Attachment File Path 6"; Text[250])
        {
            Caption = 'Attachment File Path 6';
            ObsoleteReason = 'Replaced with method AddAttachment that accepts Streams.';
#if CLEAN25
            ObsoleteState = Removed;
            ObsoleteTag = '28.0';
#else
            ObsoleteState = Pending;
            ObsoleteTag = '17.2';
#endif
        }
        field(30; "Attachment Name 6"; Text[50])
        {
            Caption = 'Attachment Name 6';
            ObsoleteReason = 'Replaced with method AddAttachment that accepts Streams.';
#if CLEAN25
            ObsoleteState = Removed;
            ObsoleteTag = '28.0';
#else
            ObsoleteState = Pending;
            ObsoleteTag = '17.2';
#endif
        }
        field(31; "Attachment File Path 7"; Text[250])
        {
            Caption = 'Attachment File Path 7';
            ObsoleteReason = 'Replaced with method AddAttachment that accepts Streams.';
#if CLEAN25
            ObsoleteState = Removed;
            ObsoleteTag = '28.0';
#else
            ObsoleteState = Pending;
            ObsoleteTag = '17.2';
#endif
        }
        field(32; "Attachment Name 7"; Text[50])
        {
            Caption = 'Attachment Name 7';
            ObsoleteReason = 'Replaced with method AddAttachment that accepts Streams.';
#if CLEAN25
            ObsoleteState = Removed;
            ObsoleteTag = '28.0';
#else
            ObsoleteState = Pending;
            ObsoleteTag = '17.2';
#endif
        }
#endif
    }

    keys
    {
        key(Key1; ID)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        Attachments: Codeunit "Temp Blob List";
        AttachmentNames: List of [Text];
        SourceTables: List of [Integer];
        SourceIDs: List of [Guid];
        SourceRelationTypes: List of [Integer];
        TargetEmailAddressErr: Label 'The target email address has not been specified.';

    procedure HasAttachments(): Boolean
    begin
        exit(Attachments.Count() > 0);
    end;

    procedure GetAttachments(var TempBlobList: Codeunit "Temp Blob List"; var Names: List of [Text])
    begin
        TempBlobList := Attachments;
        Names := AttachmentNames;
    end;

    procedure SetAttachments(TempBlobList: Codeunit "Temp Blob List"; Names: List of [Text])
    begin
        OnBeforeSetAttachments(Rec, TempBlobList, Names);
        Attachments := TempBlobList;
        AttachmentNames := Names;
    end;

    procedure AddAttachment(AttachmentStream: Instream; AttachmentName: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
    begin
        if AttachmentStream.EOS() then
            exit;
        TempBlob.CreateOutStream(OutStream);
        CopyStream(OutStream, AttachmentStream);
        Attachments.Add(TempBlob);
        AttachmentNames.Add(AttachmentName);
    end;

    procedure AddSourceDocument(TableID: Integer; SourceID: Guid)
    begin
        AddSourceDocument(TableID, SourceID, Enum::"Email Relation Type"::"Primary Source");
    end;

    procedure AddSourceDocument(TableID: Integer; SourceID: Guid; RelationType: Enum "Email Relation Type")
    begin
        SourceTables.Add(TableID);
        SourceIDs.Add(SourceID);
        SourceRelationTypes.Add(RelationType.AsInteger());
    end;

    procedure GetSourceDocuments(var SourceTableList: List of [Integer]; var SourceIDList: List of [Guid]; var SourceRelationTypeList: List of [Integer])
    begin
        SourceTableList := SourceTables;
        SourceIDList := SourceIDs;
        SourceRelationTypeList := SourceRelationTypes;
    end;

    procedure SetSourceDocuments(NewSourceTables: List of [Integer]; NewSourceIDs: List of [Guid]; NewSourceRelationTypes: List of [Integer])
    begin
        SourceTables := NewSourceTables;
        SourceIDs := NewSourceIDs;
        SourceRelationTypes := NewSourceRelationTypes;
    end;

    procedure Initialize()
    begin
        ID := CreateGuid();
    end;

    procedure Send(HideMailDialog: Boolean; EmailScenario: Enum "Email Scenario"): Boolean
    begin
        exit(Send(HideMailDialog, EmailScenario, false));
    end;

    procedure Send(HideMailDialog: Boolean; EmailScenario: Enum "Email Scenario"; Enqueue: Boolean) Result: Boolean
    var
        MailManagement: Codeunit "Mail Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSend(Rec, HideMailDialog, MailManagement, EmailScenario, Result, Enqueue, IsHandled);
        if IsHandled then
            exit(Result);
        MailManagement.SendMailOrDownload(Rec, HideMailDialog, EmailScenario, Enqueue);
        exit(MailManagement.IsSent());
    end;

    procedure SetBodyText(Value: Text)
    var
        BodyText: BigText;
        DataStream: OutStream;
    begin
        Clear(Body);
        BodyText.AddText(Value);
        Body.CreateOutStream(DataStream, TEXTENCODING::UTF8);
        BodyText.Write(DataStream);
    end;

    procedure SetBody(var TempBlob: Codeunit "Temp Blob")
    begin
        SetBody(TempBlob, false);
    end;

    procedure SetBody(var TempBlob: Codeunit "Temp Blob"; FormattedAsPlainText: Boolean)
    var
        BodyInStream: InStream;
        BodyOutStream: OutStream;
    begin
        Validate("Plaintext Formatted", FormattedAsPlainText);
        Clear(Body);
        Body.CreateOutStream(BodyOutStream, Textencoding::UTF8);
        TempBlob.CreateInStream(BodyInStream, Textencoding::UTF8);
        CopyStream(BodyOutStream, BodyInStream);
    end;

    [Scope('OnPrem')]
    procedure GetBodyText() Value: Text
    var
#if not CLEAN27
        TempBlob: Codeunit "Temp Blob";
        FileManagement: Codeunit "File Management";
        BlobInStream: InStream;
        BodyOutStream: OutStream;
#endif
        IsHandled: Boolean;
    begin
        // Note this is intended only to get the body in memory - not from the database.
        Value := '';

        IsHandled := false;
        OnBeforeGetBodyText(Rec, Value, IsHandled);
        if IsHandled then
            exit(Value);

        // If the body doesn't have a value, attempt to import the value from the file path, otherwise exit.
#if not CLEAN27
#pragma warning disable AL0432
        if not Body.HasValue() and not (("Body File Path" <> '') and Exists("Body File Path")) then
            exit;
        if not Body.HasValue() and ("Body File Path" <> '') and Exists("Body File Path") then begin
            FileManagement.BLOBImportFromServerFile(TempBlob, "Body File Path");
            TempBlob.CreateInStream(BlobInStream, TextEncoding::UTF8);
            Body.CreateOutStream(BodyOutStream);
            CopyStream(BodyOutStream, BlobInStream);
        end;
#pragma warning restore AL0432
#else
        if not Body.HasValue() then
            exit;
#endif
        Value := GetBodyTextFromBlob();

        exit(Value);
    end;

    procedure GetBodyTextFromBlob() Value: Text
    var
        BodyText: BigText;
        DataStream: InStream;
    begin
        if "Plaintext Formatted" then begin
            Body.CreateInStream(DataStream, TextEncoding::UTF8);
            BodyText.Read(DataStream);
            BodyText.GetSubText(Value, 1);
        end else begin
            Body.CreateInStream(DataStream, TextEncoding::UTF8);
            DataStream.Read(Value);
        end;
    end;

    local procedure CorrectAndValidateEmailList(var EmailAddresses: Text[250])
    var
        MailManagement: Codeunit "Mail Management";
    begin
        EmailAddresses := ConvertStr(EmailAddresses, ',', ';');
        EmailAddresses := DelChr(EmailAddresses, '<>');
        MailManagement.CheckValidEmailAddresses(EmailAddresses);
    end;

    procedure SendAsHTML(SendAsHTML: Boolean)
    begin
        Rec."Send As HTML" := SendAsHTML;
    end;

    [Scope('OnPrem')]
    procedure ValidateTarget()
    var
        ErrorMessageManagement: Codeunit "Error Message Management";
    begin
        if ("Send to" = '') and ("Send CC" = '') and ("Send BCC" = '') then
            ErrorMessageManagement.LogSimpleErrorMessage(TargetEmailAddressErr);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetBodyText(var EmailItem: Record "Email Item"; var Value: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSend(var EmailItem: Record "Email Item"; var HideMailDialog: Boolean; var MailManagement: Codeunit "Mail Management"; var EmailScenario: Enum "Email Scenario"; var Result: Boolean; var Enqueue: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetAttachments(var EmailItem: Record "Email Item"; var TempBlobList: Codeunit "Temp Blob List"; var Names: List of [Text])
    begin
    end;
}
