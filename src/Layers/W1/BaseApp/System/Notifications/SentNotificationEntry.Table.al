namespace System.Environment.Configuration;

using Microsoft.Utilities;
using System.IO;
using Microsoft.Foundation.NoSeries;
using System.Reflection;
using System.Security.AccessControl;
using System.Utilities;

table 1514 "Sent Notification Entry"
{
    Caption = 'Sent Notification Entry';
    DrillDownPageID = "Sent Notification Entries";
    LookupPageID = "Sent Notification Entries";
    Permissions = TableData "Sent Notification Entry" = rimd;
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; ID; Integer)
        {
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
        field(9; "Created Date-Time"; DateTime)
        {
            Caption = 'Created Date-Time';
        }
        field(10; "Created By"; Code[50])
        {
            Caption = 'Created By';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        field(11; "Sent Date-Time"; DateTime)
        {
            Caption = 'Sent Date-Time';
        }
        field(12; "Notification Content"; BLOB)
        {
            Caption = 'Notification Content';
        }
        field(13; "Notification Method"; Enum "Notification Method Type")
        {
            Caption = 'Notification Method';
        }
        field(14; "Aggregated with Entry"; Integer)
        {
            Caption = 'Aggregated with Entry';
            TableRelation = "Sent Notification Entry";
        }
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

    [InherentPermissions(PermissionObjectType::TableData, Database::"Sent Notification Entry", 'r')]
    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo(ID)))
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"Sent Notification Entry", 'r')]
    procedure InsertRecord()
    var
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
    begin
        if not Insert(true) then begin
            SequenceNoMgt.RebaseSeqNo(Database::"Sent Notification Entry");
            Rec.ID := SequenceNoMgt.GetNextSeqNo(Database::"Sent Notification Entry");
            Insert(true);
        end;
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"Sent Notification Entry", 'r')]
    procedure NewRecord(NotificationEntry: Record "Notification Entry"; NotificationContent: Text; NotificationMethod: Option)
    var
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
        OutStream: OutStream;
    begin
        Clear(Rec);
        OnNewRecordOnBeforeTransferFields(NotificationEntry);
        TransferFields(NotificationEntry);
        Rec.ID := SequenceNoMgt.GetNextSeqNo(Database::"Sent Notification Entry");
        "Notification Content".CreateOutStream(OutStream);
        OutStream.WriteText(NotificationContent);
        "Notification Method" := "Notification Method Type".FromInteger(NotificationMethod);
        "Sent Date-Time" := CurrentDateTime;
        OnNewRecordOnBeforeInsert(Rec, NotificationEntry, NotificationContent, NotificationMethod);
        InsertRecord();
    end;

    [Scope('OnPrem')]
    procedure ExportContent(UseDialog: Boolean): Text
    var
        TempBlob: Codeunit "Temp Blob";
        FileMgt: Codeunit "File Management";
    begin
        TempBlob.FromRecord(Rec, FieldNo("Notification Content"));

        if not TempBlob.HasValue() then begin
            Message(NotContentMsg);
            exit;
        end;

        if "Notification Method" = "Notification Method"::Note then
            exit(FileMgt.BLOBExport(TempBlob, '*.txt', UseDialog));
        exit(FileMgt.BLOBExport(TempBlob, '*.htm', UseDialog))
    end;

    [IntegrationEvent(false, false)]
    local procedure OnNewRecordOnBeforeInsert(var SentNotificationEntry: Record "Sent Notification Entry"; NotificationEntry: Record "Notification Entry"; NotificationContent: Text; NotificationMethod: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnNewRecordOnBeforeTransferFields(var NotificationEntry: Record "Notification Entry")
    begin
    end;

    var
        NotContentMsg: Label 'There is no content to export.';
}

