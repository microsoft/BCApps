// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.DataExchange;

using Microsoft.Intercompany.Setup;

/// <summary>
/// Buffers IC API log entries when running inside a job queue context where direct
/// database writes are not allowed within TryFunctions. JQ codeunits bind this
/// codeunit at the start of processing and call Finalize when back in a scope
/// that allows writes.
///
/// When no instance is bound (non-job-queue paths), RecordLogEntry inserts
/// directly as the event goes unhandled.
/// </summary>
codeunit 537 "IC API Log Context"
{
    Access = Internal;
    EventSubscriberInstance = Manual;
    Permissions = tabledata "IC API Log" = rimd;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        TempICAPILog: Record "IC API Log" temporary;
        EntryNo: Integer;

    procedure Initialize()
    begin
        Clear(TempICAPILog);
        EntryNo := 0;
        if BindSubscription(this) then;
    end;

    procedure Finalize()
    var
        ICAPILog: Record "IC API Log";
    begin
        if TempICAPILog.FindSet() then
            repeat
                ICAPILog.LogEntry(
                    TempICAPILog."IC Partner Code",
                    TempICAPILog.Direction,
                    TempICAPILog.Method,
                    TempICAPILog.GetRequestURIAsText(),
                    TempICAPILog.GetRequestBodyAsText(),
                    TempICAPILog.GetResponseBodyAsText(),
                    TempICAPILog."Status Code");
            until TempICAPILog.Next() = 0;

        TempICAPILog.DeleteAll();
        if UnbindSubscription(this) then;
    end;

    procedure RecordLogEntry(PartnerCode: Code[20]; DirectionValue: Option; MethodValue: Text; Uri: Text; RequestContent: Text; ResponseContent: Text; StatusCodeValue: Integer)
    var
        ICSetup: Record "IC Setup";
        ICAPILog: Record "IC API Log";
        Handled: Boolean;
    begin
        if not ICSetup.Get() then
            exit;
        if not ICSetup."Log API Requests" then
            exit;

        RecordLogEntryEvent(PartnerCode, DirectionValue, MethodValue, Uri, RequestContent, ResponseContent, StatusCodeValue, Handled);
        // If the event was not handled (i.e. we're not in a job queue context), log directly to the database
        if not Handled then
            ICAPILog.LogEntry(PartnerCode, DirectionValue, MethodValue, Uri, RequestContent, ResponseContent, StatusCodeValue);
    end;

    [IntegrationEvent(false, false)]
    internal procedure RecordLogEntryEvent(PartnerCode: Code[20]; DirectionValue: Option; MethodValue: Text; Uri: Text; RequestContent: Text; ResponseContent: Text; StatusCodeValue: Integer; var Handled: Boolean)
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"IC API Log Context", RecordLogEntryEvent, '', false, false)]
    local procedure OnRecordLogEntry(PartnerCode: Code[20]; DirectionValue: Option; MethodValue: Text; Uri: Text; RequestContent: Text; ResponseContent: Text; StatusCodeValue: Integer; var Handled: Boolean)
    var
        OutStream: OutStream;
    begin
        EntryNo += 1;
        TempICAPILog.Init();
        TempICAPILog."Entry No." := EntryNo;
        TempICAPILog."IC Partner Code" := PartnerCode;
        TempICAPILog.Direction := DirectionValue;
        TempICAPILog.Method := CopyStr(MethodValue, 1, MaxStrLen(TempICAPILog.Method));
        TempICAPILog."Request URI Preview" := CopyStr(Uri, 1, MaxStrLen(TempICAPILog."Request URI Preview"));
        TempICAPILog."Status Code" := StatusCodeValue;
        TempICAPILog.Insert();

        TempICAPILog."Request URI".CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(Uri);

        if RequestContent <> '' then begin
            TempICAPILog."Request Body".CreateOutStream(OutStream, TextEncoding::UTF8);
            OutStream.WriteText(RequestContent);
        end;

        if ResponseContent <> '' then begin
            TempICAPILog."Response Body".CreateOutStream(OutStream, TextEncoding::UTF8);
            OutStream.WriteText(ResponseContent);
        end;

        TempICAPILog.Modify();
        Handled := true;
    end;
}
