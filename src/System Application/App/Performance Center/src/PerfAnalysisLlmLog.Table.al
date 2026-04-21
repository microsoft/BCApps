// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

/// <summary>
/// Debug log of every LLM call made by the Performance Center. Captures the full system
/// prompt, user payload, raw response, extracted reply, and error / status code / duration
/// so a developer can see exactly what was sent and what came back.
/// </summary>
table 8407 "Perf. Analysis LLM Log"
{
    Access = Public;
    DataClassification = SystemMetadata;
    Caption = 'Performance Analysis LLM Log';

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
        }
        field(2; "Analysis Id"; Guid)
        {
            Caption = 'Analysis Id';
            TableRelation = "Performance Analysis".Id;
        }
        field(3; "Purpose"; Enum "Perf. Analysis LLM Purpose")
        {
            Caption = 'Purpose';
        }
        field(4; "Logged At"; DateTime)
        {
            Caption = 'Logged At';
        }
        field(5; "Duration (ms)"; Integer)
        {
            Caption = 'Duration (ms)';
        }
        field(6; "Success"; Boolean)
        {
            Caption = 'Success';
        }
        field(7; "Status Code"; Integer)
        {
            Caption = 'Status Code';
        }
        field(8; "Error Text"; Text[2048])
        {
            Caption = 'Error';
        }
        field(9; "System Prompt"; Blob)
        {
            Caption = 'System Prompt';
        }
        field(10; "User Payload"; Blob)
        {
            Caption = 'User Payload';
        }
        field(11; "Reply"; Blob)
        {
            Caption = 'Reply';
        }
        field(12; "Raw Response"; Blob)
        {
            Caption = 'Raw Response';
        }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(ByAnalysis; "Analysis Id", "Logged At") { }
        key(ByTime; "Logged At") { }
    }

    fieldgroups
    {
        fieldgroup(Brick; "Logged At", "Purpose", "Success", "Duration (ms)") { }
    }

    procedure SetSystemPromptText(NewText: Text)
    var
        OutStr: OutStream;
    begin
        Clear(Rec."System Prompt");
        Rec."System Prompt".CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(NewText);
    end;

    procedure GetSystemPromptText() Result: Text
    var
        InStr: InStream;
    begin
        CalcFields("System Prompt");
        Rec."System Prompt".CreateInStream(InStr, TextEncoding::UTF8);
        InStr.ReadText(Result);
    end;

    procedure SetUserPayloadText(NewText: Text)
    var
        OutStr: OutStream;
    begin
        Clear(Rec."User Payload");
        Rec."User Payload".CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(NewText);
    end;

    procedure GetUserPayloadText() Result: Text
    var
        InStr: InStream;
    begin
        CalcFields("User Payload");
        Rec."User Payload".CreateInStream(InStr, TextEncoding::UTF8);
        InStr.ReadText(Result);
    end;

    procedure SetReplyText(NewText: Text)
    var
        OutStr: OutStream;
    begin
        Clear(Rec."Reply");
        Rec."Reply".CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(NewText);
    end;

    procedure GetReplyText() Result: Text
    var
        InStr: InStream;
    begin
        CalcFields("Reply");
        Rec."Reply".CreateInStream(InStr, TextEncoding::UTF8);
        InStr.ReadText(Result);
    end;

    procedure SetRawResponseText(NewText: Text)
    var
        OutStr: OutStream;
    begin
        Clear(Rec."Raw Response");
        Rec."Raw Response".CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(NewText);
    end;

    procedure GetRawResponseText() Result: Text
    var
        InStr: InStream;
    begin
        CalcFields("Raw Response");
        Rec."Raw Response".CreateInStream(InStr, TextEncoding::UTF8);
        InStr.ReadText(Result);
    end;
}
