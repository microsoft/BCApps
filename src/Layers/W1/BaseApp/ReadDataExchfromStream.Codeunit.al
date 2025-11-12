// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.IO;

using System.Utilities;

codeunit 1413 "Read Data Exch. from Stream"
{
    TableNo = "Data Exch.";

    trigger OnRun()
    var
        TempBlob: Codeunit "Temp Blob";
        RecordRef: RecordRef;
        EventHandled: Boolean;
    begin
        // Fire the get stream event
        OnGetDataExchFileContentEvent(Rec, TempBlob, EventHandled);

        if EventHandled then begin
            Rec."File Name" := 'Data Stream';
            RecordRef.GetTable(Rec);
            TempBlob.ToRecordRef(RecordRef, Rec.FieldNo("File Content"));
            RecordRef.SetTable(Rec);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetDataExchFileContentEvent(DataExchIdentifier: Record "Data Exch."; var TempBlobResponse: Codeunit "Temp Blob"; var Handled: Boolean)
    begin
        // Event that will return the data stream from the identified subscriber
    end;
}

