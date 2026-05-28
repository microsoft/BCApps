// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Integration.Receive;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Integration.Interfaces;
using System.Utilities;

/// <summary>
/// Drives the inbound Message receive flow for a service whose connector implements
/// "IDocumentReceiverMessages". Walks the (list → download-if-needed → apply) cycle. Inlined
/// payloads from ListMessages skip the DownloadMessage call. Connector that doesn't implement
/// the extension interface is a no-op (returns 0).
/// </summary>
codeunit 6342 "E-Doc. Receive Messages"
{
    Access = Public;

    procedure Run(var Service: Record "E-Document Service") Processed: Integer
    var
        Buffer: Record "E-Doc. Inbound Msg Buffer" temporary;
        Payload: Codeunit "Temp Blob";
        BaseReceiver: Interface IDocumentReceiver;
        Receiver: Interface IDocumentReceiverMessages;
    begin
        BaseReceiver := Service."Service Integration V2";
        if not (BaseReceiver is IDocumentReceiverMessages) then
            exit(0);
        Receiver := BaseReceiver as IDocumentReceiverMessages;

        Receiver.ListMessages(Service, Buffer);
        if Buffer.FindSet() then
            repeat
                Clear(Payload);
                if Buffer.Inlined then
                    Buffer.GetPayload(Payload)
                else
                    Receiver.DownloadMessage(Service, Buffer, Payload);

                ApplyOne(Service, Buffer."Message Type", Payload);
                Processed += 1;
            until Buffer.Next() = 0;
    end;

    local procedure ApplyOne(var Service: Record "E-Document Service"; MsgType: Enum "E-Document Message Type"; var Payload: Codeunit "Temp Blob")
    var
        Msg: Record "E-Document Message";
        Parent: Record "E-Document";
        Apply: Codeunit "E-Doc. Apply Message";
        Type: Interface IEDocumentMessageType;
        Reader: Interface IEDocumentMessageReader;
    begin
        Msg.Init();
        Msg."Message Type" := MsgType;
        Msg.Direction := Msg.Direction::Incoming;
        Msg.Status := Msg.Status::Received;
        Msg."Service Code" := Service.Code;
        Msg."Related E-Document No." := 0;
        Msg.Insert();

        Type := MsgType;
        Reader := Type.GetReader();
        if not Reader.ParseMessage(Msg, Payload) then begin
            Fail(Msg, ReaderFailedErr);
            exit;
        end;

        if not Parent.Get(Msg."Related E-Document No.") then begin
            Fail(Msg, ParentNotFoundErr);
            exit;
        end;
        Msg.Modify();

        // Reception is a message-internal event — tracked on Msg.Status (Received → Applied).
        // Document log only gets written when Apply.Run advances the parent's Service Status.
        Apply.Run(Msg, Parent, Service);
    end;

    local procedure Fail(var Msg: Record "E-Document Message"; ErrorText: Text)
    begin
        Msg.Status := Msg.Status::"Apply Failed";
        Msg."Last Error" := CopyStr(ErrorText, 1, MaxStrLen(Msg."Last Error"));
        Msg.Modify();
    end;

    var
        ReaderFailedErr: Label 'Reader.ParseMessage returned false or parent not resolved';
        ParentNotFoundErr: Label 'Parent E-Document not found after parse';
}
