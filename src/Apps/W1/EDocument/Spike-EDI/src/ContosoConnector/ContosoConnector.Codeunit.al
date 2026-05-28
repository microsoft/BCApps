// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
// The Contoso connector. Real signatures for the existing transport interfaces (IDocumentSender,
// IDocumentReceiver) and the new opt-in extensions for messages (IDocumentSenderMessages,
// IDocumentReceiverMessages). Reads/writes only its own "Contoso Mailbox Entry" storage —
// zero framework calls.
//
// Spike model: Send writes ONE Outbound mailbox row. The mailbox table's OnInsert trigger
// automatically clones it as an Inbound row (the partner's echo), ready to be consumed by
// the Receive methods. No manual mailbox interaction needed.
//
// ContosoConnector inlines payloads during ListMessages, so the framework never calls
// DownloadMessage. A connector talking to a two-stage REST access point would leave
// Inlined = false and put a URL/id into Connector Token instead.
namespace Microsoft.eServices.EDocument.Spike.Contoso;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Service;
using Microsoft.eServices.EDocument.Integration.Interfaces;
using Microsoft.eServices.EDocument.Integration.Receive;
using Microsoft.eServices.EDocument.Integration.Send;
using System.Utilities;

codeunit 6927 "Contoso Connector" implements IDocumentSender, IDocumentReceiver, IDocumentSenderMessages, IDocumentReceiverMessages
{
    Access = Internal;

    // ===== IDocumentSender =====

    procedure Send(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; SendContext: Codeunit SendContext)
    var
        Entry: Record "Contoso Mailbox Entry";
        TempBlob: Codeunit "Temp Blob";
    begin
        TempBlob := SendContext.GetTempBlob();

        Entry.Init();
        Entry.Direction := Entry.Direction::Outbound;
        Entry.Kind := Entry.Kind::Document;
        Entry.Reference := CopyStr(EDocument."Document No.", 1, MaxStrLen(Entry.Reference));
        Entry."Service Code" := EDocumentService.Code;
        Entry.SetContent(TempBlob);                                 // blob in memory before Insert so OnInsert can clone it
        Entry.Insert(true);
    end;

    // ===== IDocumentReceiver =====

    procedure ReceiveDocuments(var EDocumentService: Record "E-Document Service"; DocumentsMetadata: Codeunit "Temp Blob List"; ReceiveContext: Codeunit ReceiveContext)
    var
        Entry: Record "Contoso Mailbox Entry";
        Metadata: Codeunit "Temp Blob";
        OutStream: OutStream;
    begin
        Entry.SetRange(Direction, Entry.Direction::Inbound);
        Entry.SetRange(Kind, Entry.Kind::Document);
        Entry.SetRange("Service Code", EDocumentService.Code);
        Entry.SetRange(Processed, false);
        if Entry.FindSet() then
            repeat
                Clear(Metadata);
                Metadata.CreateOutStream(OutStream, TextEncoding::UTF8);
                OutStream.WriteText(Format(Entry."Entry No."));
                DocumentsMetadata.Add(Metadata);
            until Entry.Next() = 0;
    end;

    procedure DownloadDocument(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; DocumentMetadata: Codeunit "Temp Blob"; ReceiveContext: Codeunit ReceiveContext)
    var
        Entry: Record "Contoso Mailbox Entry";
        Payload: Codeunit "Temp Blob";
        InStream: InStream;
        OutStream: OutStream;
        EntryNo: Integer;
        EntryNoText: Text;
    begin
        DocumentMetadata.CreateInStream(InStream, TextEncoding::UTF8);
        InStream.ReadText(EntryNoText);
        if not Evaluate(EntryNo, EntryNoText) then
            exit;
        if not Entry.Get(EntryNo) then
            exit;

        Entry.GetContent(Payload);
        ReceiveContext.GetTempBlob().CreateOutStream(OutStream, TextEncoding::UTF8);
        Payload.CreateInStream(InStream, TextEncoding::UTF8);
        CopyStream(OutStream, InStream);

        Entry.Processed := true;
        Entry.Modify();
    end;

    // ===== IDocumentSenderMessages =====

    procedure SendMessage(var Msg: Record "E-Document Message"; var EDocumentService: Record "E-Document Service"; SendContext: Codeunit SendContext)
    var
        Entry: Record "Contoso Mailbox Entry";
        Parent: Record "E-Document";
        TempBlob: Codeunit "Temp Blob";
    begin
        TempBlob := SendContext.GetTempBlob();
        if Parent.Get(Msg."Related E-Document No.") then;

        Entry.Init();
        Entry.Direction := Entry.Direction::Outbound;
        Entry.Kind := Entry.Kind::Message;
        Entry.Reference := CopyStr(Parent."Document No.", 1, MaxStrLen(Entry.Reference));
        Entry."Service Code" := EDocumentService.Code;
        Entry."Msg Type Ordinal" := Msg."Message Type".AsInteger();
        Entry.SetContent(TempBlob);                                 // blob in memory before Insert so OnInsert can clone it
        Entry.Insert(true);
    end;

    // ===== IDocumentReceiverMessages =====

    procedure ListMessages(var Service: Record "E-Document Service"; var Buffer: Record "E-Doc. Inbound Msg Buffer" temporary)
    var
        Entry: Record "Contoso Mailbox Entry";
        Payload: Codeunit "Temp Blob";
        NextNo: Integer;
    begin
        Entry.SetRange(Direction, Entry.Direction::Inbound);
        Entry.SetRange(Kind, Entry.Kind::Message);
        Entry.SetRange("Service Code", Service.Code);
        Entry.SetRange(Processed, false);
        if Entry.FindSet() then
            repeat
                NextNo += 1;                                        // AutoIncrement is unreliable on temp tables — assign PK manually.
                Buffer.Init();
                Buffer."Entry No." := NextNo;
                Buffer."Connector Token" := Format(Entry."Entry No.");
                Buffer."Message Type" := Enum::"E-Document Message Type".FromInteger(Entry."Msg Type Ordinal");
                Buffer."Source Timestamp" := Entry."Created At";
                Buffer.Insert();

                Entry.GetContent(Payload);
                Buffer.SetPayload(Payload);                         // mailbox already has bytes — inline them
                Buffer.Modify();

                Entry.Processed := true;
                Entry.Modify();
            until Entry.Next() = 0;
    end;

    procedure DownloadMessage(var Service: Record "E-Document Service"; Item: Record "E-Doc. Inbound Msg Buffer" temporary; var Payload: Codeunit "Temp Blob")
    begin
        // Never called for this connector — ListMessages always inlines. A connector talking
        // to a two-stage REST access point would use Item."Connector Token" to fetch the
        // payload and fill the TempBlob here.
    end;
}
