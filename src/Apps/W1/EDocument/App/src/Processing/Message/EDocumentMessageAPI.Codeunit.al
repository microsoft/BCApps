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

    procedure CreateMessage(EDocument: Record "E-Document"; MessageType: Enum "E-Document Message Type"; ResponseType: Enum "E-Doc. Response Type"; var TempBlob: Codeunit "Temp Blob"): Integer
    var
        EDocMessageMgt: Codeunit "E-Doc. Message Mgt.";
    begin
        exit(EDocMessageMgt.CreateMessage(EDocument, MessageType, EDocument.Direction::Outgoing, ResponseType, TempBlob));
    end;

    procedure SendMessage(MessageEntryNo: Integer)
    var
        EDocMessageMgt: Codeunit "E-Doc. Message Mgt.";
    begin
        EDocMessageMgt.SendMessage(MessageEntryNo);
    end;
}
