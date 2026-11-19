// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using System.Agents;
using System.Email;
using System.Utilities;

table 3327 "Payables Agent Work Item"
{
    Caption = 'Payables Agent Work Item';
    Access = Internal;
    DataClassification = CustomerContent;
    Extensible = false;
    InherentEntitlements = RIMDX;
    InherentPermissions = RIMDX;
    ReplicateData = false;

    fields
    {
        field(1; "Entry No."; BigInteger)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
            AutoIncrement = true;
        }
        field(4; "Agent Task ID"; BigInteger)
        {
            Caption = 'Agent Task ID';
            DataClassification = SystemMetadata;
            TableRelation = "Agent Task".ID;
        }
        field(5; Outcome; RecordId)
        {
            Caption = 'Outcome';
            DataClassification = CustomerContent;
        }
        field(6; "Admission Status"; Enum "PA Work Item Admission Status")
        {
            Caption = 'Admission Status';
            DataClassification = SystemMetadata;
        }
        field(7; "Rejection Reason"; Text[250])
        {
            Caption = 'Rejection Reason';
            DataClassification = SystemMetadata;
        }
        field(23; "File Name"; Text[250])
        {
            Caption = 'File Name';
            DataClassification = CustomerContent;
        }
        field(25; "Email Inbox Id"; BigInteger)
        {
            Caption = 'Email Inbox Id';
            DataClassification = SystemMetadata;
            TableRelation = "Email Inbox".Id;
        }
        field(40; "File Content"; Media)
        {
            Caption = 'File Content';
            DataClassification = CustomerContent;
        }
        field(41; "Extracted Text"; Blob)
        {
            Caption = 'Extracted Text';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(AgentTaskID; "Agent Task ID")
        {
        }
        key(ByOutcome; Outcome)
        {
        }
        key(ByAdmissionStatus; "Admission Status", "Agent Task ID")
        {
        }
    }

    var
        NoFileContentErr: Label 'There is no file to show.';

    procedure GetFileContent(var TempBlob: Codeunit "Temp Blob")
    var
        FileOutStream: OutStream;
    begin
        if not Rec."File Content".HasValue() then
            Error(NoFileContentErr);
        TempBlob.CreateOutStream(FileOutStream);
        Rec."File Content".ExportStream(FileOutStream);
    end;

    procedure HasExtractedText(): Boolean
    begin
        Rec.CalcFields("Extracted Text");
        exit(Rec."Extracted Text".HasValue());
    end;

    procedure GetExtractedText() ExtractedText: Text
    var
        TextInStream: InStream;
    begin
        if not HasExtractedText() then
            exit('');
        Rec."Extracted Text".CreateInStream(TextInStream, TextEncoding::UTF8);
        TextInStream.Read(ExtractedText);
    end;

    procedure SetExtractedText(NewExtractedText: Text)
    var
        TextOutStream: OutStream;
    begin
        Clear(Rec."Extracted Text");
        Rec."Extracted Text".CreateOutStream(TextOutStream, TextEncoding::UTF8);
        TextOutStream.WriteText(NewExtractedText);
    end;
}
