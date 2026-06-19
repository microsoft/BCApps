// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Message;

using Microsoft.eServices.EDocument;
using Microsoft.Peppol.Response;
using System.Utilities;

/// <summary>
/// Public API for creating and reading E-Document messages.
/// Format apps call CreateMessage to store a response/message blob linked to an E-Document.
/// </summary>
codeunit 6433 "E-Doc. Message Mgt."
{
    Access = Public;
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
}
