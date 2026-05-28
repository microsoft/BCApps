// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

using System.Utilities;

/// <summary>
/// Typed buffer used by "IDocumentReceiverMessages.ListMessages". One row per inbound message
/// the connector found at its access point. Carries an optional inline "Payload" — connectors
/// that return content in the list call set "Inlined" via "SetPayload"; the framework then
/// skips the per-row DownloadMessage call.
/// </summary>
table 6144 "E-Doc. Inbound Msg Buffer"
{
    Caption = 'E-Document Inbound Message Buffer';
    DataClassification = SystemMetadata;
    TableType = Temporary;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Connector Token"; Text[250])
        {
            Caption = 'Connector Token';
            ToolTip = 'Opaque to the framework. The connector uses it to fetch the payload during DownloadMessage (URL, message id, queue position, etc.).';
        }
        field(3; "Message Type"; Enum "E-Document Message Type")
        {
            Caption = 'Message Type';
        }
        field(4; "Status Code Hint"; Code[20])
        {
            Caption = 'Status Code Hint';
            ToolTip = 'Optional — if the connector knows the protocol status code at list time.';
        }
        field(5; "Source Timestamp"; DateTime)
        {
            Caption = 'Source Timestamp';
            ToolTip = 'When the access point received the message.';
        }
        field(6; "Payload"; Blob)
        {
            Caption = 'Payload';
        }
        field(7; Inlined; Boolean)
        {
            Caption = 'Inlined';
            ToolTip = 'True when the connector filled "Payload" during ListMessages. Framework skips DownloadMessage for inlined rows.';
        }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }

    /// <summary>
    /// Connector helper: store an inline payload on this buffer row. Marks the row as Inlined
    /// so the dispatcher skips DownloadMessage.
    /// </summary>
    procedure SetPayload(var Source: Codeunit "Temp Blob")
    var
        InStream: InStream;
        OutStream: OutStream;
    begin
        Source.CreateInStream(InStream, TextEncoding::UTF8);
        Rec.Payload.CreateOutStream(OutStream, TextEncoding::UTF8);
        CopyStream(OutStream, InStream);
        Rec.Inlined := true;
    end;

    /// <summary>
    /// Framework helper: read the inlined payload into a TempBlob.
    /// </summary>
    procedure GetPayload(var Target: Codeunit "Temp Blob")
    var
        InStream: InStream;
        OutStream: OutStream;
    begin
        Rec.CalcFields(Payload);
        Rec.Payload.CreateInStream(InStream, TextEncoding::UTF8);
        Target.CreateOutStream(OutStream, TextEncoding::UTF8);
        CopyStream(OutStream, InStream);
    end;
}
