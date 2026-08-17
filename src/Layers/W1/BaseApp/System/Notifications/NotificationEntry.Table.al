namespace System.Environment.Configuration;

using System.Automation;
using System.Reflection;
using System.Security.AccessControl;
using System.Security.User;

table 1511 "Notification Entry"
{
    Caption = 'Notification Entry';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; ID; Integer)
        {
            AutoIncrement = true;
            Caption = 'ID';
        }
        field(3; Type; Enum "Notification Entry Type")
        {
            Caption = 'Type';
        }
        field(4; "Recipient User ID"; Code[50])
        {
            Caption = 'Recipient User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "User Setup"."User ID";
            ValidateTableRelation = false;
        }
        field(5; "Triggered By Record"; RecordID)
        {
            Caption = 'Triggered By Record';
            DataClassification = CustomerContent;
        }
        field(6; "Link Target Page"; Integer)
        {
            Caption = 'Link Target Page';
            TableRelation = "Page Metadata".ID;
        }
        field(7; "Custom Link"; Text[250])
        {
            Caption = 'Custom Link';
            ExtendedDatatype = URL;
        }
        field(8; "Error Message"; Text[2048])
        {
            Caption = 'Error Message';
            Editable = false;
        }
        field(9; "Created Date-Time"; DateTime)
        {
            Caption = 'Created Date-Time';
            Editable = false;
        }
        field(10; "Created By"; Code[50])
        {
            Caption = 'Created By';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = User."User Name";
        }
        field(18; "Sender User ID"; Code[50])
        {
            Caption = 'Sender User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "User Setup"."User ID";
        }
    }

    keys
    {
        key(Key1; ID)
        {
            Clustered = true;
        }
        key(Key2; "Created Date-Time")
        {
        }
        key(Key3; "Triggered By Record", Type)
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        "Created Date-Time" := RoundDateTime(CurrentDateTime, 60000);
        "Created By" := UserId;
    end;

    var
        DataTypeManagement: Codeunit "Data Type Management";
        NotificationTelemetryCategoryTxt: Label 'Notifications', Locked = true;
        NoRecipientTelemetryTxt: Label 'Recipient is not set, cannot create notification', Locked = true;
        NoUserSetupTelemetryTxt: Label 'No User Setup, cannot create notification', Locked = true;
        NoValidRecordTelemetryTxt: Label 'Not a valid record, cannot create notification', Locked = true;

    procedure CreateNotificationEntry(NewType: Enum "Notification Entry Type"; RecipientUserID: Code[50]; NewRecord: Variant; NewLinkTargetPage: Integer; NewCustomLink: Text[250]; NewSenderUserID: Code[50])
    var
        NotificationSchedule: Record "Notification Schedule";
        UserSetup: Record "User Setup";
        NewRecRef: RecordRef;
        TelemetryDimensions: Dictionary of [Text, Text];
    begin
        TelemetryDimensions := GetTelemetryDimensions(NewType);

        if RecipientUserID = '' then begin
            Session.LogMessage('0000F6C', NoRecipientTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, TelemetryDimensions);
            exit;
        end;

        if not UserSetup.Get(RecipientUserID) then begin
            Session.LogMessage('0000F6D', NoUserSetupTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, TelemetryDimensions);
            exit;
        end;

        if not DataTypeManagement.GetRecordRef(NewRecord, NewRecRef) then begin
            Session.LogMessage('0000F6E', NoValidRecordTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, TelemetryDimensions);
            exit;
        end;

        if InsertRec(NewType, RecipientUserID, NewRecRef.RecordId, NewLinkTargetPage, NewCustomLink, NewSenderUserID) then
            NotificationSchedule.ScheduleNotification(Rec);
    end;

    procedure InsertRec(NewType: Enum "Notification Entry Type"; NewUserID: Code[50]; NewRecordID: RecordID; NewLinkTargetPage: Integer; NewCustomLink: Text[250]; NewSenderUserID: Code[50]): Boolean;
    begin
        if not DoesTableMatchType(NewType, NewRecordID.TableNo) then
            exit(false);

        Clear(Rec);
        Type := NewType;
        "Recipient User ID" := NewUserID;
        "Triggered By Record" := NewRecordID;
        "Link Target Page" := NewLinkTargetPage;
        "Custom Link" := NewCustomLink;
        "Sender User ID" := NewSenderUserID;
        exit(Insert(true));
    end;

    local procedure DoesTableMatchType(NewType: Enum "Notification Entry Type"; TableNo: Integer): Boolean;
    begin
        case NewType of
            "Notification Entry Type"::Approval:
                exit(TableNo = Database::"Approval Entry");
            "Notification Entry Type"::Overdue:
                exit(TableNo = Database::"Overdue Approval Entry");
        end;
        exit(true);
    end;

    internal procedure GetTelemetryDimensions(NotificationEntryType: Enum "Notification Entry Type") Dimensions: Dictionary of [Text, Text]
    begin
        Dimensions.Add('Category', NotificationTelemetryCategoryTxt);
        Dimensions.Add('NotificationEntryType', Format(NotificationEntryType.AsInteger()));
    end;
}