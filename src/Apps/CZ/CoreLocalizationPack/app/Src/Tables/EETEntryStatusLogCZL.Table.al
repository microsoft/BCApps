// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance;

using Microsoft.Utilities;
using System.Utilities;

table 31129 "EET Entry Status Log CZL"
{
    Caption = 'EET Entry Status Log';
    DrillDownPageId = "EET Entry Status Log CZL";
    LookupPageId = "EET Entry Status Log CZL";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            ToolTip = 'Specifies the number of the status log entry.';
        }
        field(5; "EET Entry No."; Integer)
        {
            Caption = 'EET Entry No.';
            TableRelation = "EET Entry CZL";
            ToolTip = 'Specifies the number of the EET entry that the status change belongs to.';
        }
        field(10; Description; Text[250])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the description of the status change, for example the response of the EET service. Select the field to display the related errors and warnings.';

            trigger OnLookup()
            begin
                ShowErrorMessages();
            end;
        }
        field(20; Status; Enum "EET Status CZL")
        {
            Caption = 'Status';
            ToolTip = 'Specifies the state of the EET entry that the entry was changed to.';
        }
        field(25; "Changed At"; DateTime)
        {
            Caption = 'Changed At';
            ToolTip = 'Specifies the date and time when the status of the EET entry was changed.';
        }
        field(30; "Request Message"; Blob)
        {
            Caption = 'Request Message';
        }
        field(31; "Response Message"; Blob)
        {
            Caption = 'Response Message';
        }
        field(35; "Global Transaction Id"; Text[250])
        {
            Caption = 'Global Transaction Id';
            ToolTip = 'Specifies the transaction ID that the EET service returned in the X-Global-Transaction-Id response header for this status change. Provide this ID to the EET service technical support when you communicate about the entry.';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "EET Entry No.")
        {
        }
    }

    trigger OnInsert()
    begin
        LockTable();
        "Entry No." := GetLastEntryNo() + 1;
    end;

    trigger OnDelete()
    begin
        ClearErrorMessages();
    end;

    var
        NoMessageErr: Label '%1 has not been saved for this status change.', Comment = '%1 = field caption (Request Message or Response Message)';
        RequestFileNameTxt: Label 'EET_Request_%1_%2.xml', Comment = '%1 = EET Entry No., %2 = EET Entry Status Log Entry No.', Locked = true;
        ResponseFileNameTxt: Label 'EET_Response_%1_%2.xml', Comment = '%1 = EET Entry No., %2 = EET Entry Status Log Entry No.', Locked = true;

    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("Entry No.")))
    end;

    procedure SetErrorMessage(var TempErrorMessage: Record "Error Message" temporary)
    var
        ErrorMessage: Record "Error Message";
    begin
        if TempErrorMessage.FindSet() then
            repeat
                ErrorMessage := TempErrorMessage;
                ErrorMessage.ID := 0;
                ErrorMessage.Validate("Record ID", RecordId());
                ErrorMessage.Validate("Context Record ID", RecordId());
                ErrorMessage.Insert(true);
            until TempErrorMessage.Next() = 0;
    end;

    procedure ShowErrorMessages()
    var
        ErrorMessage: Record "Error Message";
    begin
        ErrorMessage.SetContext(Rec);
        ErrorMessage.ShowErrorMessages(false);
    end;

    procedure ClearErrorMessages()
    var
        ErrorMessage: Record "Error Message";
    begin
        ErrorMessage.SetRange("Context Record ID", RecordId);
        ErrorMessage.DeleteAll();
    end;

    procedure SaveRequestMessage(RequestMessage: Text)
    var
        MessageOutStream: OutStream;
    begin
        if RequestMessage = '' then
            exit;
        "Request Message".CreateOutStream(MessageOutStream, TextEncoding::UTF8);
        MessageOutStream.WriteText(RequestMessage);
    end;

    procedure SaveResponseMessage(ResponseMessage: Text)
    var
        MessageOutStream: OutStream;
    begin
        if ResponseMessage = '' then
            exit;
        "Response Message".CreateOutStream(MessageOutStream, TextEncoding::UTF8);
        MessageOutStream.WriteText(ResponseMessage);
    end;

    procedure GetRequestFileName(): Text
    begin
        if not HasRequestMessage() then
            exit('');
        exit(BuildRequestFileName());
    end;

    procedure GetResponseFileName(): Text
    begin
        if not HasResponseMessage() then
            exit('');
        exit(BuildResponseFileName());
    end;

    procedure HasRequestMessage(): Boolean
    begin
        CalcFields("Request Message");
        exit("Request Message".HasValue());
    end;

    procedure HasResponseMessage(): Boolean
    begin
        CalcFields("Response Message");
        exit("Response Message".HasValue());
    end;

    procedure DownloadRequestMessage()
    var
        MessageInStream: InStream;
        FileName: Text;
    begin
        TestField("Entry No.");
        CalcFields("Request Message");
        if not "Request Message".HasValue() then
            Error(NoMessageErr, FieldCaption("Request Message"));

        FileName := BuildRequestFileName();
        "Request Message".CreateInStream(MessageInStream, TextEncoding::UTF8);
        DownloadFromStream(MessageInStream, '', '', '', FileName);
    end;

    procedure DownloadResponseMessage()
    var
        MessageInStream: InStream;
        FileName: Text;
    begin
        TestField("Entry No.");
        CalcFields("Response Message");
        if not "Response Message".HasValue() then
            Error(NoMessageErr, FieldCaption("Response Message"));

        FileName := BuildResponseFileName();
        "Response Message".CreateInStream(MessageInStream, TextEncoding::UTF8);
        DownloadFromStream(MessageInStream, '', '', '', FileName);
    end;

    local procedure BuildRequestFileName(): Text
    begin
        exit(StrSubstNo(RequestFileNameTxt, "EET Entry No.", "Entry No."));
    end;

    local procedure BuildResponseFileName(): Text
    begin
        exit(StrSubstNo(ResponseFileNameTxt, "EET Entry No.", "Entry No."));
    end;
}

