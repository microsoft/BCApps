// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.EServices.EDocument.Interfactura;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Message;

codeunit 3366 "MX Payment Response Mgt."
{
    Access = Internal;
    SingleInstance = true;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "MX Payment Complement" = rm;

    internal procedure CacheResponse(MessageEntryNo: Integer; ResponseText: Text)
    var
        EDocument: Record "E-Document";
        MessageAPI: Codeunit "E-Document Message API";
    begin
        MessageAPI.GetMessageEDocument(MessageEntryNo, EDocument);
        Responses.Set(MessageEntryNo, ResponseText);
        ParentEntries.Set(MessageEntryNo, EDocument."Entry No");
    end;

    internal procedure ClearResponse(MessageEntryNo: Integer)
    begin
        if Responses.ContainsKey(MessageEntryNo) then
            Responses.Remove(MessageEntryNo);
        if ParentEntries.ContainsKey(MessageEntryNo) then
            ParentEntries.Remove(MessageEntryNo);
    end;

    // Core saves the communication log after TrySendMessage returns. Persist here,
    // not inside the connector's SendMessage TryFunction.
    [EventSubscriber(ObjectType::Table, Database::"E-Document Integration Log", 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterIntegrationLogModify(var Rec: Record "E-Document Integration Log"; var xRec: Record "E-Document Integration Log"; RunTrigger: Boolean)
    var
        Complement: Record "MX Payment Complement";
        InterfacturaProcessing: Codeunit "Interfactura Processing";
        ResponseText: Text;
        LogResponseText: Text;
        ResponseLine: Text;
        ResponseInStream: InStream;
        ResponseOutStream: OutStream;
        UUID: Text[50];
        MessageEntryNo: Integer;
        ParentEntryNo: Integer;
        CarriageReturn: Char;
        LineFeed: Char;
    begin
        if Rec.IsTemporary() then
            exit;
        if Responses.Count() = 0 then
            exit;
        Rec.CalcFields("Response Blob");
        if not Rec."Response Blob".HasValue() then
            exit;
        Rec."Response Blob".CreateInStream(ResponseInStream);
        while not ResponseInStream.EOS do begin
            ResponseInStream.ReadText(ResponseLine);
            LogResponseText += ResponseLine;
        end;
        CarriageReturn := 13;
        LineFeed := 10;
        foreach MessageEntryNo in Responses.Keys() do begin
            ParentEntries.Get(MessageEntryNo, ParentEntryNo);
            if ParentEntryNo <> Rec."E-Doc. Entry No" then
                continue;
            Responses.Get(MessageEntryNo, ResponseText);
            if DelChr(ResponseText, '=', Format(CarriageReturn) + Format(LineFeed)) <> LogResponseText then
                continue;

            Complement.SetRange("E-Document Message Entry No.", MessageEntryNo);
            if Complement.FindFirst() then begin
                Clear(Complement."PAC Response XML");
                Complement."PAC Response XML".CreateOutStream(ResponseOutStream, TextEncoding::UTF8);
                ResponseOutStream.WriteText(ResponseText);
                if InterfacturaProcessing.TryGetStampedUUIDFromResponse(ResponseText, UUID) then begin
                    Complement."Stamped UUID" := UUID;
                    Complement."Stamped At" := CurrentDateTime();
                end;
                Complement.Modify();
            end;
            ClearResponse(MessageEntryNo);
            exit;
        end;
    end;

    var
        Responses: Dictionary of [Integer, Text];
        ParentEntries: Dictionary of [Integer, Integer];
}