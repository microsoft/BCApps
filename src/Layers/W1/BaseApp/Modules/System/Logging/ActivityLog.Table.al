// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

using System.IO;
using System.Reflection;
using System.Security.AccessControl;
using System.Utilities;

table 710 "Activity Log"
{
    Caption = 'Activity Log';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; ID; Integer)
        {
            AutoIncrement = true;
            Caption = 'ID';
        }
        field(2; "Record ID"; RecordID)
        {
            Caption = 'Record ID';
            DataClassification = CustomerContent;
        }
        field(3; "Activity Date"; DateTime)
        {
            Caption = 'Activity Date';
        }
        field(4; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        field(5; Status; Option)
        {
            Caption = 'Status';
            OptionCaption = 'Success,Failed';
            OptionMembers = Success,Failed;
        }
        field(6; Context; Text[30])
        {
            Caption = 'Context';
        }
        field(10; Description; Text[250])
        {
            Caption = 'Description';
        }
        field(20; "Activity Message"; Text[250])
        {
            Caption = 'Activity Message';
        }
        field(21; "Detailed Info"; BLOB)
        {
            Caption = 'Detailed Info';
        }
        field(22; "Table No Filter"; Integer)
        {
            Caption = 'Table No Filter';
        }
    }

    keys
    {
        key(Key1; ID)
        {
            Clustered = true;
        }
        key(Key2; "Activity Date")
        {
        }
        key(Key3; "Record ID")
        {
        }
    }

    fieldgroups
    {
    }

    var
        DataTypeNotValidErr: Label 'The specified variant type is not valid.';
        NoDetailsMsg: Label 'The log does not contain any more details.';
        ConfirmDeletingEntriesQst: Label 'Are you sure that you want to delete log entries?';
        DeletingMsg: Label 'Deleting Entries...';
        DeletedMsg: Label 'The entries were deleted from the log.';

    procedure LogActivity(RelatedVariant: Variant; NewStatus: Option; NewContext: Text[30]; ActivityDescription: Text; ActivityMessage: Text)
    var
        UserCode: Code[50];
    begin
        UserCode := '';
        LogActivityImplementation(RelatedVariant, NewStatus, NewContext, ActivityDescription, ActivityMessage, UserCode);
    end;

    procedure ShowEntries(RecordVariant: Variant)
    var
        DataTypeManagement: Codeunit "Data Type Management";
        RecRef: RecordRef;
    begin
        if not DataTypeManagement.GetRecordRef(RecordVariant, RecRef) then
            Error(DataTypeNotValidErr);

        SetRange("Record ID", RecRef.RecordId);

        Commit();
        PAGE.RunModal(PAGE::"Activity Log", Rec);
    end;

    procedure SetDetailedInfoFromStream(InputStream: InStream)
    var
        InfoOutStream: OutStream;
    begin
        "Detailed Info".CreateOutStream(InfoOutStream);
        CopyStream(InfoOutStream, InputStream);
        Modify();
    end;

    procedure SetDetailedInfoFromText(Details: Text)
    var
        OutputStream: OutStream;
    begin
        "Detailed Info".CreateOutStream(OutputStream);
        OutputStream.WriteText(Details);
        Modify();
    end;

    [Scope('OnPrem')]
    procedure Export(DefaultFileName: Text; ShowFileDialog: Boolean): Text
    var
        TempBlob: Codeunit "Temp Blob";
        FileMgt: Codeunit "File Management";
    begin
        CalcFields("Detailed Info");
        if not "Detailed Info".HasValue() then begin
            Message(NoDetailsMsg);
            exit;
        end;

        if DefaultFileName = '' then
            DefaultFileName := 'Log.txt';

        TempBlob.FromRecord(Rec, FieldNo("Detailed Info"));

        exit(FileMgt.BLOBExport(TempBlob, DefaultFileName, ShowFileDialog));
    end;

    local procedure LogActivityImplementation(RelatedVariant: Variant; NewStatus: Option; NewContext: Text[30]; ActivityDescription: Text; ActivityMessage: Text; UserCode: Code[50])
    var
        DataTypeManagement: Codeunit "Data Type Management";
        RecRef: RecordRef;
    begin
        Clear(Rec);

        if not DataTypeManagement.GetRecordRef(RelatedVariant, RecRef) then
            Error(DataTypeNotValidErr);

        "Record ID" := RecRef.RecordId;
        "Activity Date" := CurrentDateTime;
        "User ID" := UserCode;
        if "User ID" = '' then
            "User ID" := CopyStr(UserId(), 1, MaxStrLen("User ID"));
        Status := NewStatus;
        Context := NewContext;
        Description := CopyStr(ActivityDescription, 1, MaxStrLen(Description));
        "Activity Message" := CopyStr(ActivityMessage, 1, MaxStrLen("Activity Message"));
        "Table No Filter" := RecRef.Number;

        Insert(true);

        if StrLen(ActivityMessage) > MaxStrLen("Activity Message") then
            SetDetailedInfoFromText(ActivityMessage);
    end;

    procedure LogActivityForUser(RelatedVariant: Variant; NewStatus: Option; NewContext: Text[30]; ActivityDescription: Text; ActivityMessage: Text; UserCode: Code[50])
    begin
        LogActivityImplementation(RelatedVariant, NewStatus, NewContext, ActivityDescription, ActivityMessage, UserCode);
    end;

    procedure DeleteEntries(DaysOld: Integer)
    var
        Window: Dialog;
    begin
        if not Confirm(ConfirmDeletingEntriesQst) then
            exit;
        Window.Open(DeletingMsg);
        if DaysOld > 0 then
            SetFilter("Activity Date", '<=%1', CreateDateTime(Today - DaysOld, Time));
        DeleteAll();
        Window.Close();
        SetRange("Activity Date");
        Message(DeletedMsg);
    end;
}

