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
        EDocMessage.Service := EDocument.Service;
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

    procedure GetMessageEDocument(MessageEntryNo: Integer; var EDocument: Record "E-Document")
    var
        EDocMessage: Record "E-Document Message";
    begin
        EDocMessage.SetLoadFields("E-Document Entry No.");
        EDocMessage.Get(MessageEntryNo);
        EDocument.Get(EDocMessage."E-Document Entry No.");
    end;

    procedure GetMessageDirection(MessageEntryNo: Integer): Enum "E-Document Direction"
    var
        EDocMessage: Record "E-Document Message";
    begin
        EDocMessage.SetLoadFields(Direction);
        EDocMessage.Get(MessageEntryNo);
        exit(EDocMessage.Direction);
    end;

    procedure GetMessageStatus(MessageEntryNo: Integer): Enum "E-Doc. Message Status"
    var
        EDocMessage: Record "E-Document Message";
    begin
        EDocMessage.SetLoadFields(Status);
        EDocMessage.Get(MessageEntryNo);
        exit(EDocMessage.Status);
    end;

    procedure GetMessageResponseType(MessageEntryNo: Integer): Enum "E-Doc. Response Type"
    var
        EDocMessage: Record "E-Document Message";
    begin
        EDocMessage.SetLoadFields("Response Type");
        EDocMessage.Get(MessageEntryNo);
        exit(EDocMessage."Response Type");
    end;

    procedure SendMessage(MessageEntryNo: Integer)
    var
        EDocument: Record "E-Document";
        EDocumentService: Record "E-Document Service";
        EDocMessage: Record "E-Document Message";
        EDocMessageContext: Codeunit "E-Doc. Message Context";
        EDocumentLog: Codeunit "E-Document Log";
        TempBlob: Codeunit "Temp Blob";
        MessageSender: Interface IMessageSender;
        ConnectorErrorInfo: ErrorInfo;
        ConnectorErrorText: Text;
        MessageSendingErrorInfo: ErrorInfo;
    begin
        EDocMessage.Get(MessageEntryNo);
        EDocMessage.TestField(Direction, EDocMessage.Direction::Outgoing);
        if not (EDocMessage.Status in [EDocMessage.Status::Created, EDocMessage.Status::Queued, EDocMessage.Status::Error]) then
            EDocMessage.FieldError(Status);
        EDocMessage.TestField(Service);

        EDocument.Get(EDocMessage."E-Document Entry No.");
        EDocumentService.Get(EDocMessage.Service);
        GetMessageBlob(MessageEntryNo, TempBlob);
        if not TempBlob.HasValue() then
            Error(MessagePayloadErr, MessageEntryNo);

        EDocMessageContext.Initialize(EDocMessage, TempBlob);
        MessageSender := EDocumentService."Service Integration V2";
        if not TrySendMessage(MessageSender, EDocument, EDocumentService, EDocMessageContext) then begin
            ConnectorErrorText := GetLastErrorText();
            if ConnectorErrorText = '' then
                ConnectorErrorText := StrSubstNo(MessageSendingErr, MessageEntryNo);
            ConnectorErrorInfo := ErrorInfo.Create(ConnectorErrorText);
            EDocumentLog.InsertIntegrationLog(
                EDocument, EDocumentService, EDocMessageContext.Http().GetHttpRequestMessage(), EDocMessageContext.Http().GetHttpResponseMessage());
            Commit();
            ConnectorErrorInfo.DetailedMessage := StrSubstNo(MessageSendingErr, MessageEntryNo);
            ConnectorErrorInfo.DataClassification := DataClassification::SystemMetadata;
            Error(ConnectorErrorInfo);
        end;
        if not (EDocMessageContext.Status().GetStatus() in ["E-Document Service Status"::Sent, "E-Document Service Status"::"Pending Response"]) then begin
            EDocumentLog.InsertIntegrationLog(
                EDocument, EDocumentService, EDocMessageContext.Http().GetHttpRequestMessage(), EDocMessageContext.Http().GetHttpResponseMessage());
            Commit();
            MessageSendingErrorInfo.ErrorType := ErrorType::Internal;
            MessageSendingErrorInfo.Message := StrSubstNo(MessageSendingErr, MessageEntryNo);
            MessageSendingErrorInfo.DetailedMessage := StrSubstNo(MessageSendingDetailedErr, EDocMessageContext.Status().GetStatus());
            MessageSendingErrorInfo.DataClassification := DataClassification::SystemMetadata;
            Error(MessageSendingErrorInfo);
        end;

        EDocumentLog.InsertIntegrationLog(
            EDocument, EDocumentService, EDocMessageContext.Http().GetHttpRequestMessage(), EDocMessageContext.Http().GetHttpResponseMessage());
        if EDocMessageContext.Status().GetStatus() = "E-Document Service Status"::"Pending Response" then
            EDocMessage.Status := EDocMessage.Status::"Pending Response"
        else
            EDocMessage.Status := EDocMessage.Status::Sent;
        EDocMessage."Last Attempt At" := CurrentDateTime();
        Clear(EDocMessage."Last Error");
        EDocMessage.Modify();
        if EDocMessage.Status = EDocMessage.Status::"Pending Response" then begin
            Commit();
            if not TryScheduleMessageResponse(EDocMessage) then
                SetMessageSchedulingError(EDocMessage, EDocMessage.Status::"Response Error");
        end;
    end;

    procedure PollMessageResponse(MessageEntryNo: Integer)
    var
        EDocument: Record "E-Document";
        EDocumentService: Record "E-Document Service";
        EDocMessage: Record "E-Document Message";
        EDocMessageContext: Codeunit "E-Doc. Message Context";
        EDocumentLog: Codeunit "E-Document Log";
        TempBlob: Codeunit "Temp Blob";
        MessageResponseHandler: Interface IMessageResponseHandler;
        ConnectorErrorInfo: ErrorInfo;
        ConnectorErrorText: Text;
        ResponseReceived: Boolean;
    begin
        EDocMessage.Get(MessageEntryNo);
        EDocMessage.TestField(Direction, EDocMessage.Direction::Outgoing);
        EDocMessage.TestField(Status, EDocMessage.Status::"Pending Response");
        EDocMessage.TestField(Service);
        EDocument.Get(EDocMessage."E-Document Entry No.");
        EDocumentService.Get(EDocMessage.Service);
        GetMessageBlob(MessageEntryNo, TempBlob);
        EDocMessageContext.Initialize(EDocMessage, TempBlob);
        MessageResponseHandler := EDocumentService."Service Integration V2";
        if not TryGetResponse(MessageResponseHandler, EDocument, EDocumentService, EDocMessageContext, ResponseReceived) then begin
            ConnectorErrorText := GetLastErrorText();
            if ConnectorErrorText = '' then
                ConnectorErrorText := StrSubstNo(MessageResponseErr, MessageEntryNo);
            ConnectorErrorInfo := ErrorInfo.Create(ConnectorErrorText);
            EDocumentLog.InsertIntegrationLog(
                EDocument, EDocumentService, EDocMessageContext.Http().GetHttpRequestMessage(), EDocMessageContext.Http().GetHttpResponseMessage());
            Commit();
            ConnectorErrorInfo.DetailedMessage := StrSubstNo(MessageResponseErr, MessageEntryNo);
            ConnectorErrorInfo.DataClassification := DataClassification::SystemMetadata;
            Error(ConnectorErrorInfo);
        end;

        if ResponseReceived then begin
            if EDocMessageContext.Status().GetStatus() <> "E-Document Service Status"::Sent then begin
                EDocumentLog.InsertIntegrationLog(
                    EDocument, EDocumentService, EDocMessageContext.Http().GetHttpRequestMessage(), EDocMessageContext.Http().GetHttpResponseMessage());
                Commit();
                Error(MessageResponseStatusErr, MessageEntryNo, EDocMessageContext.Status().GetStatus());
            end;
            EDocMessage.Status := EDocMessage.Status::Sent;
        end else begin
            if EDocMessageContext.Status().GetStatus() <> "E-Document Service Status"::"Pending Response" then begin
                EDocumentLog.InsertIntegrationLog(
                    EDocument, EDocumentService, EDocMessageContext.Http().GetHttpRequestMessage(), EDocMessageContext.Http().GetHttpResponseMessage());
                Commit();
                Error(MessageResponseStatusErr, MessageEntryNo, EDocMessageContext.Status().GetStatus());
            end;
            EDocMessage.Status := EDocMessage.Status::"Pending Response";
        end;

        EDocumentLog.InsertIntegrationLog(
            EDocument, EDocumentService, EDocMessageContext.Http().GetHttpRequestMessage(), EDocMessageContext.Http().GetHttpResponseMessage());
        EDocMessage."Last Attempt At" := CurrentDateTime();
        Clear(EDocMessage."Last Error");
        EDocMessage.Modify();
        if not ResponseReceived then begin
            Commit();
            if not TryScheduleMessageResponse(EDocMessage) then
                SetMessageSchedulingError(EDocMessage, EDocMessage.Status::"Response Error");
        end;
    end;

    [TryFunction]
    local procedure TrySendMessage(MessageSender: Interface IMessageSender; var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; EDocMessageContext: Codeunit "E-Doc. Message Context")
    begin
        MessageSender.SendMessage(EDocument, EDocumentService, EDocMessageContext);
    end;

    [TryFunction]
    local procedure TryGetResponse(MessageResponseHandler: Interface IMessageResponseHandler; var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; EDocMessageContext: Codeunit "E-Doc. Message Context"; var ResponseReceived: Boolean)
    begin
        ResponseReceived := MessageResponseHandler.GetResponse(EDocument, EDocumentService, EDocMessageContext);
    end;

    procedure QueueMessage(MessageEntryNo: Integer)
    var
        EDocMessage: Record "E-Document Message";
    begin
        EDocMessage.Get(MessageEntryNo);
        EDocMessage.TestField(Direction, EDocMessage.Direction::Outgoing);
        EDocMessage.TestField(Status, EDocMessage.Status::Created);
        EDocMessage.TestField(Service);

        EDocMessage.Status := EDocMessage.Status::Queued;
        EDocMessage.Modify();
        Commit();
        if TryScheduleMessageSend(EDocMessage) then
            exit;

        SetMessageSchedulingError(EDocMessage, EDocMessage.Status::Error);
    end;

    local procedure TryScheduleMessageSend(EDocMessage: Record "E-Document Message"): Boolean
    var
        EDocumentBackgroundJobs: Codeunit "E-Document Background Jobs";
    begin
        exit(EDocumentBackgroundJobs.TryScheduleMessageSend(EDocMessage));
    end;

    local procedure TryScheduleMessageResponse(EDocMessage: Record "E-Document Message"): Boolean
    var
        EDocumentBackgroundJobs: Codeunit "E-Document Background Jobs";
    begin
        exit(EDocumentBackgroundJobs.TryScheduleMessageResponse(EDocMessage));
    end;

    local procedure SetMessageSchedulingError(var EDocMessage: Record "E-Document Message"; ErrorStatus: Enum "E-Doc. Message Status")
    var
        SchedulingError: Text;
    begin
        SchedulingError := GetLastErrorText();
        EDocMessage.Get(EDocMessage."Entry No.");
        EDocMessage.Status := ErrorStatus;
        EDocMessage."Last Attempt At" := CurrentDateTime();
        EDocMessage."Retry Count" += 1;
        EDocMessage."Last Error" := CopyStr(SchedulingError, 1, MaxStrLen(EDocMessage."Last Error"));
        EDocMessage.Modify();
        ClearLastError();
    end;

    procedure RetryMessage(MessageEntryNo: Integer)
    var
        EDocMessage: Record "E-Document Message";
    begin
        EDocMessage.Get(MessageEntryNo);
        EDocMessage.TestField(Direction, EDocMessage.Direction::Outgoing);
        if EDocMessage.Status <> EDocMessage.Status::"Response Error" then
            EDocMessage.TestField(Status, EDocMessage.Status::Error);
        EDocMessage.TestField(Service);

        if EDocMessage.Status = EDocMessage.Status::"Response Error" then
            EDocMessage.Status := EDocMessage.Status::"Pending Response"
        else
            EDocMessage.Status := EDocMessage.Status::Queued;
        EDocMessage.Modify();
        Commit();
        if EDocMessage.Status = EDocMessage.Status::"Pending Response" then begin
            if not TryScheduleMessageResponse(EDocMessage) then
                SetMessageSchedulingError(EDocMessage, EDocMessage.Status::"Response Error");
        end else
            if not TryScheduleMessageSend(EDocMessage) then
                SetMessageSchedulingError(EDocMessage, EDocMessage.Status::Error);
    end;

    procedure RegisterExternalDocumentReference(EDocument: Record "E-Document"; ServiceCode: Code[20]; ExternalDocumentID: Text[250])
    var
        EDocExternalReference: Record "E-Doc. External Reference";
        EDocumentService: Record "E-Document Service";
    begin
        if ExternalDocumentID = '' then
            Error(ExternalDocumentIDRequiredErr);

        EDocument.Get(EDocument."Entry No");
        EDocument.TestField(Service, ServiceCode);
        EDocumentService.Get(ServiceCode);

        EDocExternalReference.SetCurrentKey(Service, "External Document ID");
        EDocExternalReference.SetRange(Service, ServiceCode);
        EDocExternalReference.SetRange("External Document ID", ExternalDocumentID);
        if EDocExternalReference.FindFirst() then begin
            if EDocExternalReference."E-Document Entry No." = EDocument."Entry No" then
                exit;
            Error(ExternalDocumentIDConflictErr, ExternalDocumentID, ServiceCode);
        end;

        EDocExternalReference.Init();
        EDocExternalReference.Service := ServiceCode;
        EDocExternalReference."External Document ID" := ExternalDocumentID;
        EDocExternalReference."E-Document Entry No." := EDocument."Entry No";
        EDocExternalReference."Created At" := CurrentDateTime();
        EDocExternalReference.Insert();
    end;

    procedure CreateIncomingMessage(ServiceCode: Code[20]; ExternalDocumentID: Text[250]; ExternalMessageID: Text[250]; MessageType: Enum "E-Document Message Type"; ResponseType: Enum "E-Doc. Response Type"; ReceivedAt: DateTime; var TempBlob: Codeunit "Temp Blob"): Integer
    var
        EDocument: Record "E-Document";
        EDocExternalReference: Record "E-Doc. External Reference";
        EDocMessage: Record "E-Document Message";
        MessageEntryNo: Integer;
    begin
        if ExternalDocumentID = '' then
            Error(ExternalDocumentIDRequiredErr);
        if ExternalMessageID = '' then
            Error(ExternalMessageIDRequiredErr);
        if not TempBlob.HasValue() then
            Error(IncomingMessagePayloadRequiredErr);

        EDocMessage.LockTable();
        EDocMessage.SetCurrentKey(Service, "External Message ID");
        EDocMessage.SetRange(Service, ServiceCode);
        EDocMessage.SetRange("External Message ID", ExternalMessageID);
        if EDocMessage.FindFirst() then
            exit(EDocMessage."Entry No.");

        EDocExternalReference.SetCurrentKey(Service, "External Document ID");
        EDocExternalReference.SetRange(Service, ServiceCode);
        EDocExternalReference.SetRange("External Document ID", ExternalDocumentID);
        if not EDocExternalReference.FindFirst() then
            Error(ExternalDocumentNotFoundErr, ExternalDocumentID, ServiceCode);

        EDocument.Get(EDocExternalReference."E-Document Entry No.");
        MessageEntryNo := CreateMessage(EDocument, MessageType, "E-Document Direction"::Incoming, ResponseType, TempBlob);
        EDocMessage.Get(MessageEntryNo);
        EDocMessage.Status := EDocMessage.Status::Received;
        EDocMessage."External Message ID" := ExternalMessageID;
        EDocMessage."External Document ID" := ExternalDocumentID;
        if ReceivedAt = 0DT then
            EDocMessage."Received At" := CurrentDateTime()
        else
            EDocMessage."Received At" := ReceivedAt;
        EDocMessage.Modify();
        exit(MessageEntryNo);
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
        MessagePayloadErr: Label 'E-Document message %1 does not contain a payload.', Comment = '%1 = E-Document message entry number';
        MessageSendingErr: Label 'E-Document message %1 could not be sent.', Comment = '%1 = E-Document message entry number';
        MessageResponseErr: Label 'A response for E-Document message %1 could not be retrieved.', Comment = '%1 = E-Document message entry number';
        MessageSendingDetailedErr: Label 'The E-Document message integration returned status %1.', Comment = '%1 = integration status';
        MessageResponseStatusErr: Label 'The connector returned invalid response status %2 for E-Document message %1.', Comment = '%1 = message entry number, %2 = connector status';
        ExternalDocumentIDRequiredErr: Label 'An external document ID is required.';
        ExternalMessageIDRequiredErr: Label 'An external message ID is required.';
        IncomingMessagePayloadRequiredErr: Label 'An incoming E-Document message payload is required.';
        ExternalDocumentIDConflictErr: Label 'External document ID %1 is already associated with another E-Document for service %2.', Comment = '%1 = external document ID, %2 = service code';
        ExternalDocumentNotFoundErr: Label 'External document ID %1 is not registered for E-Document service %2.', Comment = '%1 = external document ID, %2 = service code';
}
