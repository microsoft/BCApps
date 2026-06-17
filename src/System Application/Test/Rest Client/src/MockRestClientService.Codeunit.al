// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.RestClient;
using System.TestLibraries.Utilities;

codeunit 134965 "Mock Rest Client Service"
{
    var
        Assert: Codeunit "Library Assert";
        WebRequestResponse: Codeunit "Library - Variable Storage";
        BaseURLTxt: Label 'https://localhost';
        GetUrlTxt: Label 'https://localhost/get';
        PostUrlTxt: Label 'https://localhost/post';
        PatchUrlTxt: Label 'https://localhost/patch';
        PutUrlTxt: Label 'https://localhost/put';
        DeleteUrlTxt: Label 'https://localhost/delete';
        ExpectedRequestQueryParameters: Dictionary of [Text, Text];

    procedure GetBaseURL(): Text
    begin
        exit(BaseURLTxt);
    end;

    procedure GetGetUrl(): Text
    begin
        exit(GetUrlTxt);
    end;

    procedure GetPostUrl(): Text
    begin
        exit(PostUrlTxt);
    end;

    procedure GetPatchUrl(): Text
    begin
        exit(PatchUrlTxt);
    end;

    procedure GetPutUrl(): Text
    begin
        exit(PutUrlTxt);
    end;

    procedure GetDeleteUrl(): Text
    begin
        exit(DeleteUrlTxt);
    end;

    procedure SetResponse(Response: Text)
    begin
        WebRequestResponse.Enqueue(Response);
    end;

    procedure SetQueryParameters(QueryParameters: Dictionary of [Text, Text])
    begin
        ExpectedRequestQueryParameters := QueryParameters;
    end;

    procedure HandleRequest(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        if not Request.Path.StartsWith(BaseURLTxt) then
            exit;

        VerifyRequestQueryParameters(Request.QueryParameters);

        if Request.Path.StartsWith(GetUrlTxt) then begin
            Response.Content.WriteFrom(WebRequestResponse.DequeueText());
            Response.HttpStatusCode := 200;
            exit;
        end;

        if Request.Path = PostUrlTxt then begin
            Response.Content.WriteFrom(WebRequestResponse.DequeueText());
            Response.HttpStatusCode := 200;
            exit;
        end;

        if Request.Path = PatchUrlTxt then begin
            Response.Content.WriteFrom(WebRequestResponse.DequeueText());
            Response.HttpStatusCode := 200;
            exit;
        end;

        if Request.Path = PutUrlTxt then begin
            Response.Content.WriteFrom(WebRequestResponse.DequeueText());
            Response.HttpStatusCode := 200;
            exit;
        end;

        if Request.Path = DeleteUrlTxt then begin
            Response.Content.WriteFrom(WebRequestResponse.DequeueText());
            Response.HttpStatusCode := 200;
            exit;
        end;

        Assert.Fail('Unexpected request path: ' + Request.Path);
    end;

    procedure VerifyAllExpectedRequestWereHandled()
    begin
        WebRequestResponse.AssertEmpty();
    end;

    local procedure VerifyRequestQueryParameters(RequestQueryParameters: Dictionary of [Text, Text])
    var
        QueryParameter: Text;
    begin
        Assert.AreEqual(ExpectedRequestQueryParameters.Count(), RequestQueryParameters.Count(), 'Wrong number of query parameters in request.');

        if RequestQueryParameters.Count() = 0 then
            exit;

        foreach QueryParameter in ExpectedRequestQueryParameters.Keys() do begin
            Assert.IsTrue(RequestQueryParameters.ContainsKey(QueryParameter), 'Missing query parameter: ' + QueryParameter);
            Assert.AreEqual(ExpectedRequestQueryParameters.Get(QueryParameter), RequestQueryParameters.Get(QueryParameter), 'Wrong value for query parameter: ' + QueryParameter);
        end;
    end;
}