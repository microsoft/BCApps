// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Message;

using Microsoft.eServices.EDocument.Integration;
using Microsoft.eServices.EDocument.Integration.Action;
using System.Utilities;

codeunit 6533 "E-Doc. Message Context"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    internal procedure Initialize(EDocMessage: Record "E-Document Message"; TempBlob: Codeunit "Temp Blob")
    begin
        MessageEntryNo := EDocMessage."Entry No.";
        MessageType := EDocMessage."Message Type";
        ResponseType := EDocMessage."Response Type";
        Payload := TempBlob;
    end;

    /// <summary>
    /// Gets the entry number of the child E-Document message being sent.
    /// </summary>
    /// <returns>The E-Document message entry number.</returns>
    procedure GetMessageEntryNo(): Integer
    begin
        exit(MessageEntryNo);
    end;

    /// <summary>
    /// Gets the semantic type of the child E-Document message.
    /// </summary>
    /// <returns>The E-Document message type.</returns>
    procedure GetMessageType(): Enum "E-Document Message Type"
    begin
        exit(MessageType);
    end;

    /// <summary>
    /// Gets the response type represented by the child message.
    /// </summary>
    /// <returns>The E-Document response type.</returns>
    procedure GetResponseType(): Enum "E-Doc. Response Type"
    begin
        exit(ResponseType);
    end;

    /// <summary>
    /// Gets the message payload.
    /// </summary>
    /// <returns>A temporary blob containing the message payload.</returns>
    procedure GetTempBlob(): Codeunit "Temp Blob"
    begin
        exit(Payload);
    end;

    /// <summary>
    /// Gets the HTTP state used to record the connector request and response.
    /// </summary>
    /// <returns>The HTTP message state.</returns>
    procedure Http(): Codeunit "Http Message State"
    begin
        exit(HttpMessageState);
    end;

    /// <summary>
    /// Gets the transport result. A connector must set the status to Sent or Pending Response after successful transmission.
    /// </summary>
    /// <returns>The integration action status.</returns>
    procedure Status(): Codeunit "Integration Action Status"
    begin
        exit(IntegrationActionStatus);
    end;

    var
        HttpMessageState: Codeunit "Http Message State";
        IntegrationActionStatus: Codeunit "Integration Action Status";
        Payload: Codeunit "Temp Blob";
        MessageType: Enum "E-Document Message Type";
        ResponseType: Enum "E-Doc. Response Type";
        MessageEntryNo: Integer;
}