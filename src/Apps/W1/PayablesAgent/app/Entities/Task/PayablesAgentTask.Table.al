// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using System.Agents;
using System.Email;
using System.Utilities;

table 3327 "Payables Agent Task"
{
    Caption = 'Payables Agent Task';
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
        field(6; "Intake Status"; Enum "PA Task Intake Status")
        {
            Caption = 'Intake Status';
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
        field(41; "File Content As Text"; Blob)
        {
            Caption = 'File Content As Text';
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
        key(ByIntakeStatus; "Intake Status", "Agent Task ID")
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

    procedure HasFileContentAsText(): Boolean
    begin
        Rec.CalcFields("File Content As Text");
        exit(Rec."File Content As Text".HasValue());
    end;

    procedure GetFileContentAsText() FileContentAsText: Text
    var
        TextInStream: InStream;
    begin
        if not HasFileContentAsText() then
            exit('');
        Rec."File Content As Text".CreateInStream(TextInStream, TextEncoding::UTF8);
        TextInStream.Read(FileContentAsText);
    end;

    procedure SetFileContentAsText(NewFileContentAsText: Text)
    var
        TextOutStream: OutStream;
    begin
        Clear(Rec."File Content As Text");
        Rec."File Content As Text".CreateOutStream(TextOutStream, TextEncoding::UTF8);
        TextOutStream.WriteText(NewFileContentAsText);
    end;
}
