// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.ForNAV;

using Microsoft.eServices.EDocument.Integration.Send;

codeunit 6425 "ForNAV Peppol SMP"
{
    Access = internal;
    procedure CallSMP(Req: Text; var InputObject: JsonObject; action: Text; var Error: integer; var Message: Text) OutputObject: JsonObject;
    var
        Setup: Record "ForNAV Peppol Setup";
        SendContext: Codeunit SendContext;
        PeppolSetup: Codeunit "ForNAV Peppol Setup";
        HttpClient: HttpClient;
        HttpResponse: HttpResponseMessage;
        HttpRequestMessage: HttpRequestMessage;
        HttpContent: HttpContent;
        StatusCode: Integer;
        InStr: InStream;
        ResponseObject: JsonObject;
        Token: JsonToken;
        Url: Text;
        HttpHeaders: HttpHeaders;
        ServiceErr: Label 'SMP %1 service error : %2 %3', Comment = '%1 = action %2 = status code %3 = message';
    begin
        Setup.InitSetup();

        Url := PeppolSetup.GetBaseUrl('SMP');
        case Req of
            'Post':
                HttpContent.WriteFrom(Format(InputObject));
            'Put':
                HttpContent.WriteFrom(Format(InputObject));
        end;

        HttpRequestMessage.SetRequestUri(Url);
        HttpRequestMessage.GetHeaders(HttpHeaders);
        HttpHeaders.Add('action', action);

        HttpRequestMessage.Content := HttpContent;
        HttpRequestMessage.Method(Req.ToUpper());
        SendContext.Http().SetHttpRequestMessage(HttpRequestMessage);
        if PeppolSetup.Send(HttpClient, SendContext.Http()) = 401 then begin
            Error := 401;
            exit;
        end;
        HttpResponse := SendContext.Http().GetHttpResponseMessage();
        StatusCode := HttpResponse.HttpStatusCode;
        if (Error = -1) and (StatusCode = 0) then begin
            Error := StatusCode;
            exit;
        end;
        Message := HttpResponse.ReasonPhrase;

        SendContext.GetTempBlob().CreateInStream(InStr);
        SendContext.Http().GetHttpResponseMessage().Content.ReadAs(InStr);

        if ResponseObject.ReadFrom(InStr) then begin
            if (StatusCode = 200) and ResponseObject.Get('statuscode', Token) then
                StatusCode := Token.AsValue().AsInteger();
            if ResponseObject.Get('message', Token) and Token.IsValue and not Token.AsValue().IsNull then
                Message := Token.AsValue().AsText();
            if (StatusCode >= 300) and (Error <> -1) and (StatusCode <> Error) then begin
                if ResponseObject.Get('payload', Token) then
                    Message += ': ' + Token.AsValue().AsText();
                Error(ServiceErr, action, StatusCode, Message);
            end else
                Error := StatusCode;
            if ResponseObject.Get('payload', Token) then
                if Token.IsObject then
                    OutputObject := Token.AsObject()
                else
                    if Token.IsValue and not Token.AsValue().IsNull then
                        OutputObject.ReadFrom(Token.AsValue().AsText());
        end else
            Error(ServiceErr, action, StatusCode, Message);
    end;

    procedure CallSMP(Req: Text; Action: Text; var Error: Integer; var Message: Text): JsonObject;
    var
        DummyObject: JsonObject;
    begin
        exit(CallSMP(Req, DummyObject, Action, Error, Message));
    end;

    internal procedure ParticipantExists(var Setup: record "ForNAV Peppol Setup")
    var
        OutputObject: JsonObject;
        Message: Text;
        Result: Integer;
        LicenseLbl: Label 'You need a valid ForNAV license to use this App "%1"', Comment = '%1 = meessage';
        ConnectionLbl: Label 'You are not authorized to use the ForNAV Peppol network. Please authorize./Error: %1', Comment = '%1 = error';
        LicensePeppolAccessLbl: Label 'You need update your ForNAV license to be able to use this app, please contact your partner';
        SetupInAnotherBCInstanceLbl: Label 'This peppolid is already published in another company or Business Central installation - you need to unpublish it to use it with this company';
    begin
        Result := -1; // Any
        OutputObject := CallSMP('Get', 'participant', Result, Message);
        case result of
            0:
                Setup.Status := Setup.Status::"Offline";
            401:
                begin
                    Setup.Authorized := false;
                    Message(ConnectionLbl, GetLastErrorText());
                end;
            402:
                begin
                    Setup.Status := Setup.Status::"Unlicensed";
                    Message(LicenseLbl, Message);
                end;
            403:
                begin
                    Setup.Status := Setup.Status::"Unlicensed";
                    Message(LicensePeppolAccessLbl);
                end;
            404:
                Setup.Status := Setup.Status::"Not published";
            200:
                Setup.Status := Setup.Status::Published;
            409:
                begin
                    Message(SetupInAnotherBCInstanceLbl);
                    Setup.Status := Setup.Status::"Published in another company or installation";
                end;
            423:
                Setup.Status := Setup.Status::"Published by ForNAV using another AAD tenant";
            451:
                Setup.Status := Setup.Status::"Published by another AP";
            428:
                Setup.Status := Setup.Status::"Waiting for approval";
            else
                Error('Unknown error %1', Result);
        end;
        Setup.SetValues(OutputObject);
        Setup.Modify();
    end;

    internal procedure CreateParticipant(var Setup: record "ForNAV Peppol Setup")
    var
        PeppolSetup: Codeunit "ForNAV Peppol Setup";
        InputObject, OutputObject : JsonObject;
        Error: Integer;
        Message: Text;
    begin
        // Used by Azure function - do not modify
        InputObject.Add('Identifier', Setup.ID());
        InputObject.Add('ForNAVIncomingEDocumentsUrl', GetUrl(ClientType::Api, Setup.CurrentCompany(), ObjectType::Page, Page::"ForNAV Incoming E-Docs Api"));
        InputObject.Add('BusinessEntity', Setup.CreateBusinessEntity());
        InputObject.Add('License', PeppolSetup.GetJLicense());
        error := 409;
        OutputObject := CallSMP('Post', InputObject, 'participant', error, message);
        if error = 409 then
            Error('Conflict');
        Setup.Status := Setup.Status::Published;
        Setup.Modify();
    end;

    internal procedure DeleteParticipant(var Setup: record "ForNAV Peppol Setup")
    var
        Error: Integer;
        message: Text;
    begin
        Error := 204;
        CallSMP('Delete', 'participant', Error, message);
        Setup.Status := Setup.Status::"Not published";
        Setup.Modify();
    end;
}
