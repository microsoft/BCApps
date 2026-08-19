// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Message;

using Microsoft.eServices.EDocument.Integration;
using Microsoft.eServices.EDocument.Integration.Action;
using System.Utilities;

/// <summary>
/// Provides E-Document message metadata and transport state to service integrations.
/// </summary>
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
    /// Gets the entry number of the message being transported.
    /// </summary>
    procedure GetMessageEntryNo(): Integer
    begin
        exit(MessageEntryNo);
    end;

    /// <summary>
    /// Gets the type of the message being transported.
    /// </summary>
    procedure GetMessageType(): Enum "E-Document Message Type"
    begin
        exit(MessageType);
    end;

    /// <summary>
    /// Gets the response type of the message being transported.
    /// </summary>
    procedure GetResponseType(): Enum "E-Doc. Response Type"
    begin
        exit(ResponseType);
    end;

    /// <summary>
    /// Gets the message payload.
    /// </summary>
    procedure GetTempBlob(): Codeunit "Temp Blob"
    begin
        exit(Payload);
    end;

    /// <summary>
    /// Gets the HTTP state for the transport operation.
    /// </summary>
    procedure Http(): Codeunit "Http Message State"
    begin
        exit(HttpMessageState);
    end;

    /// <summary>
    /// Gets the status state for the transport operation.
    /// </summary>
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