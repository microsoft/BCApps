// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
// Simulates the network for the spike. The connector's Send methods write TWO rows for each
// artifact: an Outbound row (audit of what we put on the wire) and an Inbound row (the partner's
// echo, ready to be consumed by Receive). The connector's Receive methods only consume Inbound
// rows. No manual mailbox interaction needed — the round-trip happens at Send time.
namespace Microsoft.eServices.EDocument.Spike.Contoso;

using System.Utilities;

table 6902 "Contoso Mailbox Entry"
{
    Caption = 'Contoso Mailbox Entry';
    DataClassification = CustomerContent;
    LookupPageId = "Contoso Mailbox";
    DrillDownPageId = "Contoso Mailbox";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
        }
        field(2; "Direction"; Option)
        {
            Caption = 'Direction';
            OptionMembers = Outbound,Inbound;
            OptionCaption = 'Outbound,Inbound';
        }
        field(3; "Kind"; Option)
        {
            Caption = 'Kind';
            OptionMembers = Document,Message;
            OptionCaption = 'Document,Message';
        }
        field(4; "Reference"; Code[50])
        {
            Caption = 'Reference';                                  // typically the document number
        }
        field(5; "Service Code"; Code[20])
        {
            Caption = 'Service Code';
        }
        field(6; "Content"; Blob)
        {
            Caption = 'Content';
        }
        field(7; "Created At"; DateTime)
        {
            Caption = 'Created At';
        }
        field(8; "Processed"; Boolean)
        {
            Caption = 'Processed';                                  // set when the framework has consumed the row via Receive
        }
        field(9; "Msg Type Ordinal"; Integer)
        {
            Caption = 'Msg Type Ordinal';                           // populated when Kind = Message; identifies the "E-Document Message Type" enum value
        }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(Available; Direction, Kind, "Service Code", "Processed", "Created At") { }
    }

    trigger OnInsert()
    var
        Twin: Record "Contoso Mailbox Entry";
    begin
        if Rec."Created At" = 0DT then
            Rec."Created At" := CurrentDateTime();

        // Network simulator: every row inserted gets its opposite-direction twin so the
        // mailbox always shows the pair. Whichever direction is inserted, the other side gets
        // created automatically. Insert(false) on the twin skips this trigger and avoids
        // infinite recursion. The blob carries via record assignment because the connector
        // wrote it onto Rec before Insert.
        Twin := Rec;
        Twin."Entry No." := 0;
        case Rec.Direction of
            Rec.Direction::Outbound:
                Twin.Direction := Twin.Direction::Inbound;
            Rec.Direction::Inbound:
                Twin.Direction := Twin.Direction::Outbound;
        end;
        Twin.Insert(false);
    end;

    procedure SetContent(Source: Codeunit "Temp Blob")
    var
        InStream: InStream;
        OutStream: OutStream;
    begin
        Source.CreateInStream(InStream, TextEncoding::UTF8);
        Rec."Content".CreateOutStream(OutStream, TextEncoding::UTF8);
        CopyStream(OutStream, InStream);
    end;

    procedure GetContent(var Target: Codeunit "Temp Blob")
    var
        InStream: InStream;
        OutStream: OutStream;
    begin
        CalcFields("Content");
        Rec."Content".CreateInStream(InStream, TextEncoding::UTF8);
        Target.CreateOutStream(OutStream, TextEncoding::UTF8);
        CopyStream(OutStream, InStream);
    end;
}
