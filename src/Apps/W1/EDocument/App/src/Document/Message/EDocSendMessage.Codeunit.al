// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

using Microsoft.eServices.EDocument.Integration.Interfaces;
using Microsoft.eServices.EDocument.Integration.Send;
using System.Utilities;

/// <summary>
/// Outbound orchestration for E-Document Messages. Creates the row in Pending Send, asks the
/// Type's Writer to generate the payload, dispatches via the connector's opt-in
/// "IDocumentSenderMessages" extension, then hands off to "E-Doc. Apply Message" for the
/// post-send state-transition step. Writes "E-Document Log" entries at every checkpoint.
/// </summary>
codeunit 6341 "E-Doc. Send Message"
{
    Access = Public;

    procedure Run(var Parent: Record "E-Document"; var Service: Record "E-Document Service"; MsgType: Enum "E-Document Message Type"; TriggerSource: Enum "E-Doc. Msg. Trigger Source") Msg: Record "E-Document Message"
    var
        Apply: Codeunit "E-Doc. Apply Message";
        Context: Codeunit SendContext;
        TempBlob: Codeunit "Temp Blob";
        BaseSender: Interface IDocumentSender;
        MsgSender: Interface IDocumentSenderMessages;
        Type: Interface IEDocumentMessageType;
        Writer: Interface IEDocumentMessageWriter;
    begin
        BaseSender := Service."Service Integration V2";
        if not (BaseSender is IDocumentSenderMessages) then
            Error(ConnectorDoesNotSupportMessagesErr, Service.Code);
        MsgSender := BaseSender as IDocumentSenderMessages;

        CreateRow(Msg, Parent, Service, MsgType);

        Type := MsgType;
        Writer := Type.GetWriter();
        if not Writer.GenerateMessage(Parent, Msg, TempBlob) then begin
            Fail(Msg, Msg.Status::"Send Failed", WriterFailedErr);
            exit;
        end;

        Context.SetTempBlob(TempBlob);
        MsgSender.SendMessage(Msg, Service, Context);
        Msg."Sent / Received At" := CurrentDateTime();

        // Generation / send are message-internal operational events — tracked on Msg.Status.
        // Document log only gets written when Apply.Run advances the parent's Service Status.
        Apply.Run(Msg, Parent, Service);

        Msg.Status := Msg.Status::Sent;
        Msg.Modify();
    end;

    local procedure CreateRow(var Msg: Record "E-Document Message"; Parent: Record "E-Document"; Service: Record "E-Document Service"; MsgType: Enum "E-Document Message Type")
    begin
        Msg.Init();
        Msg."Related E-Document No." := Parent."Entry No";
        Msg."Message Type" := MsgType;
        Msg.Direction := Msg.Direction::Outgoing;
        Msg.Status := Msg.Status::"Pending Send";
        Msg."Service Code" := Service.Code;
        Msg.Insert(true);
    end;

    local procedure Fail(var Msg: Record "E-Document Message"; NewStatus: Enum "E-Doc. Message Status"; ErrorText: Text)
    begin
        Msg.Status := NewStatus;
        Msg."Last Error" := CopyStr(ErrorText, 1, MaxStrLen(Msg."Last Error"));
        Msg.Modify();
    end;

    var
        ConnectorDoesNotSupportMessagesErr: Label 'The service %1 does not support sending E-Document Messages (connector does not implement IDocumentSenderMessages).', Comment = '%1 = service code';
        WriterFailedErr: Label 'Writer.GenerateMessage returned false';
}
