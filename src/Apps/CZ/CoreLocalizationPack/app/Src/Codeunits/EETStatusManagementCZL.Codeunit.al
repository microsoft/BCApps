// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance;

using System.Utilities;

codeunit 31098 "EET Status Management CZL"
{
    Permissions = tabledata "EET Entry Status Log CZL" = rimd;

    var
        XGlobalTransactionIdTok: Label 'X-Global-Transaction-Id', Locked = true;

    [EventSubscriber(ObjectType::Table, Database::"EET Entry CZL", OnAfterChangeStatus, '', false, false)]
    local procedure LogStatusChangeOnAfterChangeStatus(var EETEntryCZL: Record "EET Entry CZL"; NewStatus: Enum "EET Status CZL"; NewDescription: Text; var TempErrorMessage: Record "Error Message"; HttpRequestMessage: HttpRequestMessage; HttpResponseMessage: HttpResponseMessage)
    begin
        if EETEntryCZL.IsTemporary() then
            exit;

        EETEntryCZL.TestField("Entry No.");
        CreateEETEntryStatusLog(EETEntryCZL, NewDescription, TempErrorMessage, HttpRequestMessage, HttpResponseMessage);
    end;

    local procedure CreateEETEntryStatusLog(EETEntryCZL: Record "EET Entry CZL"; Description: Text; var TempErrorMessage: Record "Error Message"; HttpRequestMessage: HttpRequestMessage; HttpResponseMessage: HttpResponseMessage)
    var
        EETEntryStatusLogCZL: Record "EET Entry Status Log CZL";
        RequestMessage, ResponseMessage : Text;
    begin
        EETEntryStatusLogCZL.Init();
        EETEntryStatusLogCZL."EET Entry No." := EETEntryCZL."Entry No.";
        EETEntryStatusLogCZL.Status := EETEntryCZL."Status";
        EETEntryStatusLogCZL."Changed At" := EETEntryCZL."Status Last Changed At";
        EETEntryStatusLogCZL.Description := CopyStr(Description, 1, MaxStrLen(EETEntryStatusLogCZL.Description));
        EETEntryStatusLogCZL."Global Transaction Id" := GetGlobalTransactionId(HttpResponseMessage);
        if EETEntryCZL.IsRequestMessageLogEnabled() then
            if HttpRequestMessage.Content().ReadAs(RequestMessage) then
                EETEntryStatusLogCZL.SaveRequestMessage(RequestMessage);
        if EETEntryCZL.IsResponseMessageLogEnabled() then
            if HttpResponseMessage.Content().ReadAs(ResponseMessage) then
                EETEntryStatusLogCZL.SaveResponseMessage(ResponseMessage);
        EETEntryStatusLogCZL.Insert(true);

        EETEntryStatusLogCZL.SetErrorMessage(TempErrorMessage);
    end;

    local procedure GetGlobalTransactionId(HttpResponseMessage: HttpResponseMessage): Text[250]
    begin
        exit(CopyStr(GetResponseHeaderValue(HttpResponseMessage, XGlobalTransactionIdTok), 1, 250));
    end;

    local procedure GetResponseHeaderValue(HttpResponseMessage: HttpResponseMessage; HeaderName: Text): Text
    var
        ResponseHttpHeaders: HttpHeaders;
        HeaderValues: List of [Text];
    begin
        ResponseHttpHeaders := HttpResponseMessage.Headers();
        if ResponseHttpHeaders.GetValues(HeaderName, HeaderValues) then
            if HeaderValues.Count() > 0 then
                exit(HeaderValues.Get(1));
        exit('');
    end;
}
