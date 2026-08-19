// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Message;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Integration.Interfaces;
using System.Utilities;

/// <summary>
/// Internal helper for creating and reading E-Document messages, used by other
/// codeunits within this app (e.g. format handlers) to store or retrieve a
/// response/message blob linked to an E-Document.
/// </summary>
codeunit 6433 "E-Doc. Message Mgt."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    Permissions =
        tabledata "E-Document Message" = rim,
        tabledata "E-Doc. Data Storage" = rim;

    /// <summary>
    /// Creates an E-Document message record and stores the XML payload blob.
    /// Returns the Entry No. of the new message row.
    /// </summary>
    procedure CreateMessage(EDocument: Record "E-Document"; MessageType: Enum "E-Document Message Type"; var TempBlob: Codeunit "Temp Blob"): Integer
    begin
        exit(CreateMessage(EDocument, MessageType, "E-Document Direction"::Outgoing, "E-Doc. Response Type"::None, TempBlob));
    end;

    /// <summary>
    /// Creates an E-Document message record with an explicit direction and stores the XML payload blob.
    /// Returns the Entry No. of the new message row.
    /// </summary>
    procedure CreateMessage(EDocument: Record "E-Document"; MessageType: Enum "E-Document Message Type"; Direction: Enum "E-Document Direction"; var TempBlob: Codeunit "Temp Blob"): Integer
    begin
        exit(CreateMessage(EDocument, MessageType, Direction, "E-Doc. Response Type"::None, TempBlob));
    end;

    /// <summary>
    /// Creates an E-Document message record with an explicit direction and response type, and stores the XML payload blob.
    /// Returns the Entry No. of the new message row.
    /// </summary>
    procedure CreateMessage(EDocument: Record "E-Document"; MessageType: Enum "E-Document Message Type"; Direction: Enum "E-Document Direction"; ResponseType: Enum "E-Doc. Response Type"; var TempBlob: Codeunit "Temp Blob"): Integer
    begin
        exit(CreateMessage(EDocument, MessageType, Direction, ResponseType, EDocument.Service, TempBlob));
    end;

    /// <summary>
    /// Creates an E-Document message for an explicit service and stores its payload.
    /// </summary>
    procedure CreateMessage(EDocument: Record "E-Document"; MessageType: Enum "E-Document Message Type"; Direction: Enum "E-Document Direction"; ServiceCode: Code[20]; var TempBlob: Codeunit "Temp Blob"): Integer
    begin
        exit(CreateMessage(EDocument, MessageType, Direction, "E-Doc. Response Type"::None, ServiceCode, TempBlob));
    end;

    /// <summary>
    /// Creates an E-Document message for an explicit service and response type, and stores its payload.
    /// </summary>
    procedure CreateMessage(EDocument: Record "E-Document"; MessageType: Enum "E-Document Message Type"; Direction: Enum "E-Document Direction"; ResponseType: Enum "E-Doc. Response Type"; ServiceCode: Code[20]; var TempBlob: Codeunit "Temp Blob"): Integer
    var
        EDocMessage: Record "E-Document Message";
        DataStorageEntryNo: Integer;
    begin
        DataStorageEntryNo := InsertDataStorage(TempBlob);

        EDocMessage.Init();
        EDocMessage."E-Document Entry No." := EDocument."Entry No";
        EDocMessage."Message Type" := MessageType;
        EDocMessage.Direction := Direction;
        EDocMessage."Response Type" := ResponseType;
        EDocMessage.Status := EDocMessage.Status::Created;
        EDocMessage.Service := ServiceCode;
        EDocMessage."Data Storage Entry No." := DataStorageEntryNo;
        EDocMessage."Created At" := CurrentDateTime();
        EDocMessage.Insert();
        exit(EDocMessage."Entry No.");
    end;

    /// <summary>
    /// Loads the payload blob for the given message entry number into TempBlob.
    /// </summary>
    procedure GetMessageBlob(MessageEntryNo: Integer; var TempBlob: Codeunit "Temp Blob")
    var
        EDocMessage: Record "E-Document Message";
        EDocDataStorage: Record "E-Doc. Data Storage";
    begin
        if not EDocMessage.Get(MessageEntryNo) then
            exit;
        if not EDocDataStorage.Get(EDocMessage."Data Storage Entry No.") then
            exit;
        TempBlob := EDocDataStorage.GetTempBlob();
    end;

    /// <summary>
    /// Sends an outgoing message through the message sender configured on its E-Document service.
    /// </summary>
    procedure SendMessage(MessageEntryNo: Integer)
    var
        EDocument: Record "E-Document";
        EDocumentService: Record "E-Document Service";
        EDocMessage: Record "E-Document Message";
        EDocMessageContext: Codeunit "E-Doc. Message Context";
        EDocumentLog: Codeunit "E-Document Log";
        IMessageSender: Interface IMessageSender;
        ResultStatus: Enum "E-Document Service Status";
    begin
        EDocMessage.Get(MessageEntryNo);
        EDocMessage.TestField(Direction, EDocMessage.Direction::Outgoing);
        EDocMessage.TestField(Status, EDocMessage.Status::Created);
        EDocMessage.TestField(Service);

        EDocument.Get(EDocMessage."E-Document Entry No.");
        EDocumentService.Get(EDocMessage.Service);
        if EDocumentService."Service Integration V2" = EDocumentService."Service Integration V2"::"No Integration" then
            Error(NoMessageIntegrationErr, EDocumentService.Code);

        InitializeMessageContext(EDocMessage, EDocMessageContext);
        IMessageSender := EDocumentService."Service Integration V2";
        IMessageSender.SendMessage(EDocument, EDocumentService, EDocMessageContext);
        ResultStatus := EDocMessageContext.Status().GetStatus();
        ValidateMessageResultStatus(MessageEntryNo, ResultStatus);

        EDocumentLog.InsertIntegrationLog(
            EDocument, EDocumentService, EDocMessageContext.Http().GetHttpRequestMessage(), EDocMessageContext.Http().GetHttpResponseMessage());

        EDocMessage.Get(MessageEntryNo);
        SetMessageStatus(EDocMessage, ResultStatus);
        EDocMessage.Modify();
    end;

    /// <summary>
    /// Retrieves the response for an asynchronously sent message.
    /// </summary>
    procedure GetMessageResponse(MessageEntryNo: Integer)
    var
        EDocument: Record "E-Document";
        EDocumentService: Record "E-Document Service";
        EDocMessage: Record "E-Document Message";
        EDocMessageContext: Codeunit "E-Doc. Message Context";
        EDocumentLog: Codeunit "E-Document Log";
        IMessageResponseHandler: Interface IMessageResponseHandler;
        ResultStatus: Enum "E-Document Service Status";
    begin
        EDocMessage.Get(MessageEntryNo);
        EDocMessage.TestField(Direction, EDocMessage.Direction::Outgoing);
        EDocMessage.TestField(Status, EDocMessage.Status::"Pending Response");
        EDocMessage.TestField(Service);

        EDocument.Get(EDocMessage."E-Document Entry No.");
        EDocumentService.Get(EDocMessage.Service);
        InitializeMessageContext(EDocMessage, EDocMessageContext);

        IMessageResponseHandler := EDocumentService."Service Integration V2";
        IMessageResponseHandler.GetMessageResponse(EDocument, EDocumentService, EDocMessageContext);
        ResultStatus := EDocMessageContext.Status().GetStatus();
        ValidateMessageResultStatus(MessageEntryNo, ResultStatus);

        EDocumentLog.InsertIntegrationLog(
            EDocument, EDocumentService, EDocMessageContext.Http().GetHttpRequestMessage(), EDocMessageContext.Http().GetHttpResponseMessage());

        EDocMessage.Get(MessageEntryNo);
        SetMessageStatus(EDocMessage, ResultStatus);
        EDocMessage.Modify();
    end;

    local procedure InitializeMessageContext(EDocMessage: Record "E-Document Message"; var EDocMessageContext: Codeunit "E-Doc. Message Context")
    var
        TempBlob: Codeunit "Temp Blob";
    begin
        GetMessageBlob(EDocMessage."Entry No.", TempBlob);
        if not TempBlob.HasValue() then
            Error(MessagePayloadErr, EDocMessage."Entry No.");

        EDocMessageContext.Initialize(EDocMessage, TempBlob);
    end;

    local procedure ValidateMessageResultStatus(MessageEntryNo: Integer; ResultStatus: Enum "E-Document Service Status")
    begin
        if ResultStatus in [ResultStatus::Sent, ResultStatus::"Pending Response"] then
            exit;

        Error(MessageSendingErr, MessageEntryNo, ResultStatus);
    end;

    local procedure SetMessageStatus(var EDocMessage: Record "E-Document Message"; ResultStatus: Enum "E-Document Service Status")
    begin
        if ResultStatus = ResultStatus::Sent then
            EDocMessage.Status := EDocMessage.Status::Sent
        else
            EDocMessage.Status := EDocMessage.Status::"Pending Response";
    end;

    local procedure InsertDataStorage(TempBlob: Codeunit "Temp Blob"): Integer
    var
        EDocDataStorage: Record "E-Doc. Data Storage";
        EDocRecRef: RecordRef;
    begin
        if not TempBlob.HasValue() then
            exit(0);

        EDocDataStorage.Init();
        EDocDataStorage.Insert();
        EDocDataStorage.Name := '';
        EDocDataStorage."Data Storage Size" := TempBlob.Length();
        EDocRecRef.GetTable(EDocDataStorage);
        TempBlob.ToRecordRef(EDocRecRef, EDocDataStorage.FieldNo("Data Storage"));
        EDocRecRef.Modify();
        exit(EDocDataStorage."Entry No.");
    end;

    var
        NoMessageIntegrationErr: Label 'E-Document service %1 does not have an integration configured for sending messages.', Comment = '%1 = E-Document service code';
        MessagePayloadErr: Label 'E-Document message %1 does not contain a payload.', Comment = '%1 = E-Document message entry number';
        MessageSendingErr: Label 'E-Document message %1 could not be sent. The integration returned status %2.', Comment = '%1 = E-Document message entry number, %2 = integration status';
}
