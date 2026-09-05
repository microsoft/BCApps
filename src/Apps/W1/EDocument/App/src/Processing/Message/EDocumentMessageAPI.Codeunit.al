// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Message;

using Microsoft.eServices.EDocument;
using System.Utilities;

codeunit 6532 "E-Document Message API"
{
    Access = Public;
    InherentEntitlements = X;

    /// <summary>
    /// Creates an outgoing child message for an E-Document and stores its payload.
    /// </summary>
    /// <param name="EDocument">The parent E-Document.</param>
    /// <param name="MessageType">The semantic message type.</param>
    /// <param name="ResponseType">The response represented by the message.</param>
    /// <param name="TempBlob">The message payload.</param>
    /// <returns>The entry number of the created E-Document message.</returns>
    procedure CreateMessage(EDocument: Record "E-Document"; MessageType: Enum "E-Document Message Type"; ResponseType: Enum "E-Doc. Response Type"; var TempBlob: Codeunit "Temp Blob"): Integer
    var
        EDocMessageMgt: Codeunit "E-Doc. Message Mgt.";
    begin
        exit(EDocMessageMgt.CreateMessage(EDocument, MessageType, EDocument.Direction::Outgoing, ResponseType, TempBlob));
    end;

    /// <summary>
    /// Gets the parent E-Document of an E-Document message.
    /// </summary>
    /// <param name="MessageEntryNo">The entry number of the E-Document message.</param>
    /// <param name="EDocument">The parent E-Document.</param>
    procedure GetMessageEDocument(MessageEntryNo: Integer; var EDocument: Record "E-Document")
    var
        EDocMessageMgt: Codeunit "E-Doc. Message Mgt.";
    begin
        EDocMessageMgt.GetMessageEDocument(MessageEntryNo, EDocument);
    end;

    /// <summary>
    /// Gets the direction of an E-Document message.
    /// </summary>
    /// <param name="MessageEntryNo">The entry number of the E-Document message.</param>
    /// <returns>The message direction.</returns>
    procedure GetMessageDirection(MessageEntryNo: Integer): Enum "E-Document Direction"
    var
        EDocMessageMgt: Codeunit "E-Doc. Message Mgt.";
    begin
        exit(EDocMessageMgt.GetMessageDirection(MessageEntryNo));
    end;

    /// <summary>
    /// Gets the processing status of an E-Document message.
    /// </summary>
    /// <param name="MessageEntryNo">The entry number of the E-Document message.</param>
    /// <returns>The message processing status.</returns>
    procedure GetMessageStatus(MessageEntryNo: Integer): Enum "E-Doc. Message Status"
    var
        EDocMessageMgt: Codeunit "E-Doc. Message Mgt.";
    begin
        exit(EDocMessageMgt.GetMessageStatus(MessageEntryNo));
    end;

    /// <summary>
    /// Gets the response type represented by an E-Document message.
    /// </summary>
    /// <param name="MessageEntryNo">The entry number of the E-Document message.</param>
    /// <returns>The message response type.</returns>
    procedure GetMessageResponseType(MessageEntryNo: Integer): Enum "E-Doc. Response Type"
    var
        EDocMessageMgt: Codeunit "E-Doc. Message Mgt.";
    begin
        exit(EDocMessageMgt.GetMessageResponseType(MessageEntryNo));
    end;

    /// <summary>
    /// Sends a previously created outgoing E-Document message through its E-Document service.
    /// </summary>
    /// <param name="MessageEntryNo">The entry number of the E-Document message to send.</param>
    procedure SendMessage(MessageEntryNo: Integer)
    var
        EDocMessageMgt: Codeunit "E-Doc. Message Mgt.";
    begin
        EDocMessageMgt.SendMessage(MessageEntryNo);
    end;

    /// <summary>
    /// Queues a previously created outgoing E-Document message for background transmission.
    /// </summary>
    /// <param name="MessageEntryNo">The entry number of the E-Document message to queue.</param>
    procedure QueueMessage(MessageEntryNo: Integer)
    var
        EDocMessageMgt: Codeunit "E-Doc. Message Mgt.";
    begin
        EDocMessageMgt.QueueMessage(MessageEntryNo);
    end;

    /// <summary>
    /// Requeues a failed outgoing E-Document message for background transmission using its stored payload.
    /// </summary>
    /// <param name="MessageEntryNo">The entry number of the failed E-Document message to retry.</param>
    procedure RetryMessage(MessageEntryNo: Integer)
    var
        EDocMessageMgt: Codeunit "E-Doc. Message Mgt.";
    begin
        EDocMessageMgt.RetryMessage(MessageEntryNo);
    end;

    /// <summary>
    /// Polls the service for the asynchronous response to an outgoing child message.
    /// </summary>
    /// <param name="MessageEntryNo">The entry number of a message in Pending Response status.</param>
    procedure PollMessageResponse(MessageEntryNo: Integer)
    var
        EDocMessageMgt: Codeunit "E-Doc. Message Mgt.";
    begin
        EDocMessageMgt.PollMessageResponse(MessageEntryNo);
    end;

    /// <summary>
    /// Associates an external service document identifier with an E-Document for later message correlation.
    /// </summary>
    /// <param name="EDocument">The E-Document known by the external service.</param>
    /// <param name="ServiceCode">The E-Document service that issued the identifier.</param>
    /// <param name="ExternalDocumentID">The service-specific document identifier.</param>
    procedure RegisterExternalDocumentReference(EDocument: Record "E-Document"; ServiceCode: Code[20]; ExternalDocumentID: Text[250])
    var
        EDocMessageMgt: Codeunit "E-Doc. Message Mgt.";
    begin
        EDocMessageMgt.RegisterExternalDocumentReference(EDocument, ServiceCode, ExternalDocumentID);
    end;

    /// <summary>
    /// Stores an incoming child message and correlates it to an E-Document by service-specific identifiers.
    /// </summary>
    /// <param name="ServiceCode">The service from which the message was received.</param>
    /// <param name="ExternalDocumentID">The external identifier of the parent document.</param>
    /// <param name="ExternalMessageID">The external identifier used to deduplicate the message.</param>
    /// <param name="MessageType">The semantic message type.</param>
    /// <param name="ResponseType">The response represented by the message.</param>
    /// <param name="ReceivedAt">The source timestamp, or zero to use the current date and time.</param>
    /// <param name="TempBlob">The original message payload.</param>
    /// <returns>The entry number of the new or previously stored E-Document message.</returns>
    procedure CreateIncomingMessage(ServiceCode: Code[20]; ExternalDocumentID: Text[250]; ExternalMessageID: Text[250]; MessageType: Enum "E-Document Message Type"; ResponseType: Enum "E-Doc. Response Type"; ReceivedAt: DateTime; var TempBlob: Codeunit "Temp Blob"): Integer
    var
        EDocMessageMgt: Codeunit "E-Doc. Message Mgt.";
    begin
        exit(EDocMessageMgt.CreateIncomingMessage(ServiceCode, ExternalDocumentID, ExternalMessageID, MessageType, ResponseType, ReceivedAt, TempBlob));
    end;
}
