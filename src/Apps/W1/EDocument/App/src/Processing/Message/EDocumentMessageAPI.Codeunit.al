// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Message;

using Microsoft.eServices.EDocument;
using System.Utilities;

/// <summary>
/// Provides public operations for E-Document messages.
/// </summary>
codeunit 6436 "E-Document Message API"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    /// <summary>
    /// Creates an E-Document message with an explicit direction and stores its payload.
    /// </summary>
    procedure CreateMessage(EDocument: Record "E-Document"; MessageType: Enum "E-Document Message Type"; Direction: Enum "E-Document Direction"; var TempBlob: Codeunit "Temp Blob"): Integer
    var
        EDocMessageMgt: Codeunit "E-Doc. Message Mgt.";
    begin
        exit(EDocMessageMgt.CreateMessage(EDocument, MessageType, Direction, TempBlob));
    end;

    /// <summary>
    /// Loads the payload for the specified E-Document message.
    /// </summary>
    procedure GetMessageBlob(MessageEntryNo: Integer; var TempBlob: Codeunit "Temp Blob")
    var
        EDocMessageMgt: Codeunit "E-Doc. Message Mgt.";
    begin
        EDocMessageMgt.GetMessageBlob(MessageEntryNo, TempBlob);
    end;
}