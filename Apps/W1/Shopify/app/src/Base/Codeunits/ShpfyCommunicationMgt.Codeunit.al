/// <summary>
/// Codeunit Shpfy Communication Mgt. (ID 30103).
/// </summary>
codeunit 30103 "Shpfy Communication Mgt."
{
    Access = Internal;
    SingleInstance = true;

    var
        Shop: Record "Shpfy Shop";
        CommunicationEvents: Codeunit "Shpfy Communication Events";
        GraphQLQueries: Codeunit "Shpfy GraphQL Queries";
        NextExecutionTime: DateTime;
        VersionTok: Label '2023-01', Locked = true;
        OutgoingRequestsNotEnabledConfirmLbl: Label 'Importing data to your Shopify shop is not enabled, do you want to go to shop card to enable?';
        OutgoingRequestsNotEnabledErr: Label 'Importing data to your Shopify shop is not enabled, navigate to shop card to enable.';
        IsTestInProgress: Boolean;
        CategoryTok: Label 'Shopify Integration', Locked = true;
        QueryParamTooLongTxt: Label 'Query param length exceeded 50000.', Locked = true;
        QueryParamTooLongErr: Label 'Request length exceeded Shopify API limit.';
        ProductCreateQueryParamTooLongErr: Label 'Request length exceeded Shopify API limit. This may be due to longer marketing text or embed images.';
        RequestTelemetryLbl: Label '%1 request with ID %2 has been made to Shopify.', Comment = '%1 - method, %2 - request ID', Locked = true;

    /// <summary> 
    /// Create Web Request URL.
    /// </summary>
    /// <param name="UrlPath">Parameter of type Text.</param>
    /// <returns>Return value of type Text.</returns>
    internal procedure CreateWebRequestURL(UrlPath: Text): Text
    begin
        exit(CreateWebRequestURL(UrlPath, ApiVersion()))
    end;

    /// <summary> 
    /// Create Web Request URL.
    /// </summary>
    /// <param name="UrlPath">Parameter of type Text.</param>
    /// <param name="ApiVersion">Parameter of type Text.</param>
    /// <returns>Return value of type Text.</returns>
    internal procedure CreateWebRequestURL(UrlPath: Text; ApiVersion: Text): Text
    begin
        Shop.TestField("Shopify URL");
        if UrlPath.StartsWith('gift_cards') then
            if Shop."Shopify URL".EndsWith('/') then
                exit(Shop."Shopify URL" + 'admin/' + UrlPath)
            else
                exit(Shop."Shopify URL" + '/admin/' + UrlPath)
        else
            if Shop."Shopify URL".EndsWith('/') then
                exit(Shop."Shopify URL" + 'admin/api/' + ApiVersion + '/' + UrlPath)
            else
                exit(Shop."Shopify URL" + '/admin/api/' + ApiVersion + '/' + UrlPath);
    end;

    /// <summary> 
    /// Description for ExecuteGraphQL.
    /// </summary>
    /// <param name="GraphQLType">Parameter of type Enum "Shopify GraphQL Type".</param>
    /// <returns>Return variable "JsonToken".</returns>
    internal procedure ExecuteGraphQL(GraphQLType: Enum "Shpfy GraphQL Type"): JsonToken
    var
        Parameters: Dictionary of [Text, Text];
    begin
        exit(ExecuteGraphQL(GraphQLType, Parameters));
    end;

    /// <summary> 
    /// Description for ExecuteGraphQL.
    /// </summary>
    /// <param name="GraphQLType">Parameter of type Enum "Shopify GraphQL Type".</param>
    /// <param name="Parameters">Parameter of type Dictionary of [Text, Text].</param>
    /// <returns>Return variable "JsonToken".</returns>
    internal procedure ExecuteGraphQL(GraphQLType: Enum "Shpfy GraphQL Type"; Parameters: Dictionary of [Text, Text]): JsonToken
    var
        ExpectedCost: Integer;
        GraphQLQuery: Text;
    begin
        GraphQLQuery := GraphQLQueries.GetQuery(GraphQLType, Parameters, ExpectedCost);
        exit(ExecuteGraphQL(GraphQLQuery, ExpectedCost));
    end;

    /// <summary> 
    /// Execute GraphQL.
    /// </summary>
    /// <param name="GraphQLQuery">Parameter of type Text.</param>
    /// <returns>Return value of type JsonToken.</returns>
    internal procedure ExecuteGraphQL(GraphQLQuery: Text): JsonToken
    begin
        exit(ExecuteGraphQL(GraphQLQuery, 0));
    end;

    /// <summary> 
    /// Description for ExecuteGraphQL.
    /// </summary>
    /// <param name="GraphQLQuery">Parameter of type Text.</param>
    /// <param name="ExpectedCost">Parameter of type Decimal.</param>
    /// <returns>Return variable "JsonToken".</returns>
    internal procedure ExecuteGraphQL(GraphQLQuery: Text; ExpectedCost: Decimal): JsonToken
    var
        ResponseHeaders: HttpHeaders;
    begin
        exit(ExecuteGraphQL(GraphQLQuery, ResponseHeaders, ExpectedCost));
    end;

    /// <summary> 
    /// Execute GraphQL.
    /// </summary>
    /// <param name="GraphQLQuery">Parameter of type Text.</param>
    /// <param name="ResponseHeaders">Parameter of type HttpHeaders.</param>
    /// <returns>Return variable "JResponse" of type JsonToken.</returns>
    internal procedure ExecuteGraphQL(GraphQLQuery: Text; var ResponseHeaders: HttpHeaders) JResponse: JsonToken
    begin
        exit(ExecuteGraphQL(GraphQLQuery, ResponseHeaders, 0));
    end;

    /// <summary> 
    /// Description for ExecuteGraphQL.
    /// </summary>
    /// <param name="GraphQLQuery">Parameter of type Text.</param>
    /// <param name="ResponseHeaders">Parameter of type HttpHeaders.</param>
    /// <param name="ExpectedCost">Parameter of type Decimal.</param>
    /// <returns>Return variable JResponse of type JsonToken.</returns>
    internal procedure ExecuteGraphQL(GraphQLQuery: Text; var ResponseHeaders: HttpHeaders; ExpectedCost: Decimal) JResponse: JsonToken
    var
        ShpfyGraphQLRateLimit: Codeunit "Shpfy GraphQL Rate Limit";
        ShpfyJsonHelper: Codeunit "Shpfy Json Helper";
        ReceivedData: Text;
        ErrorOnShopifyErr: Label 'Error(s) on Shopify:\ \%1', Comment = '%1 = Errors from json structure.';
        NoJsonErr: Label 'The response from Shopify contains no JSON. \Requested: %1 \Response: %2', Comment = '%1 = The request = %2 = Received data';
    begin
        CheckQueryLength(GraphQLQuery);
        ShpfyGraphQLRateLimit.WaitForRequestAvailable(ExpectedCost);
        ReceivedData := ExecuteWebRequest(CreateWebRequestURL('graphql.json'), 'POST', GraphQLQuery, ResponseHeaders, 3);
        if JResponse.ReadFrom(ReceivedData) then begin
            ShpfyGraphQLRateLimit.SetQueryCost(ShpfyJsonHelper.GetJsonToken(JResponse, 'extensions.cost.throttleStatus'));
            while JResponse.AsObject().Contains('errors') and Format(JResponse).Contains('THROTTLED') do begin
                ShpfyGraphQLRateLimit.WaitForRequestAvailable(ExpectedCost);
                if JResponse.ReadFrom(ExecuteWebRequest(CreateWebRequestURL('graphql.json'), 'POST', GraphQLQuery, ResponseHeaders, 3)) then
                    ShpfyGraphQLRateLimit.SetQueryCost(ShpfyJsonHelper.GetJsonToken(JResponse, 'extensions.cost.throttleStatus'));
            end;
            if JResponse.AsObject().Contains('errors') then
                Error(ErrorOnShopifyErr, Format(ShpfyJsonHelper.GetJsonToken(JResponse, 'errors')));
        end else
            Error(NoJsonErr, GraphQLQuery, ReceivedData);
    end;

    /// <summary> 
    /// Execute WebRequest.
    /// </summary>
    /// <param name="Url">Parameter of type Text.</param>
    /// <param name="Method">Parameter of type Text.</param>
    /// <param name="JRequest">Parameter of type JsonToken.</param>
    /// <returns>Return value of type JsonToken.</returns>
    internal procedure ExecuteWebRequest(Url: Text; Method: Text; JRequest: JsonToken): JsonToken
    var
        ResponseHeaders: HttpHeaders;
    begin
        exit(ExecuteWebRequest(Url, Method, JRequest, ResponseHeaders));
    end;

    /// <summary> 
    /// Execute Web Request.
    /// </summary>
    /// <param name="Url">Parameter of type Text.</param>
    /// <param name="Method">Parameter of type Text.</param>
    /// <param name="JRequest">Parameter of type JsonToken.</param>
    /// <param name="nextPageUrl">Parameter of type Text.</param>
    /// <returns>Return variable "JResponse" of type JsonToken.</returns>
    internal procedure ExecuteWebRequest(Url: Text; Method: Text; JRequest: JsonToken; var nextPageUrl: Text) JResponse: JsonToken
    var
        ResponseHeaders: HttpHeaders;
        LinkInfo: List of [Text];
        Links: array[1] of Text;
    begin
        JResponse := ExecuteWebRequest(Url, Method, JRequest, ResponseHeaders);
        Clear(nextPageUrl);
        if ResponseHeaders.Contains('Link') then
            if ResponseHeaders.GetValues('Link', Links) then
                if Links[1] <> '' then begin
                    LinkInfo := Links[1].Split(', ');
                    LinkInfo := LinkInfo.Get(LinkInfo.Count).Split('; ');
                    if LinkInfo.Get(2) = 'rel="next"' then
                        nextPageUrl := CopyStr(LinkInfo.Get(1), 2, StrLen(LinkInfo.Get(1)) - 2);
                end;
    end;

    /// <summary> 
    /// Execute Web Request.
    /// </summary>
    /// <param name="Url">Parameter of type Text.</param>
    /// <param name="Method">Parameter of type Text.</param>
    /// <param name="JRequest">Parameter of type JsonToken.</param>
    /// <param name="ResponseHeaders">Parameter of type HttpHeaders.</param>
    /// <returns>Return variable "JResponse" of type JsonToken.</returns>
    internal procedure ExecuteWebRequest(Url: Text; Method: Text; JRequest: JsonToken; var ResponseHeaders: HttpHeaders) JResponse: JsonToken
    var
        Request: Text;
    begin
        JRequest.WriteTo(Request);
        if JResponse.ReadFrom(ExecuteWebRequest(Url, Method, Request, ResponseHeaders)) then;
    end;

    /// <summary> 
    /// Execute Web Request.
    /// </summary>
    /// <param name="Url">Parameter of type Text.</param>
    /// <param name="Method">Parameter of type Text.</param>
    /// <param name="Request">Parameter of type Text.</param>
    /// <returns>Return value of type Text.</returns>
    internal procedure ExecuteWebRequest(Url: Text; Method: Text; Request: Text): Text
    var
        ResponseHeaders: HttpHeaders;
    begin
        exit(ExecuteWebRequest(Url, Method, Request, ResponseHeaders));
    end;

    /// <summary> 
    /// Execute Web Request.
    /// </summary>
    /// <param name="Url">Parameter of type Text.</param>
    /// <param name="Method">Parameter of type Text.</param>
    /// <param name="Request">Parameter of type Text.</param>
    /// <param name="ResponseHeaders">Parameter of type HttpHeaders.</param>
    /// <returns>Return variable "Response" of type Text.</returns>
    internal procedure ExecuteWebRequest(Url: Text; Method: Text; Request: Text; var ResponseHeaders: HttpHeaders) Response: Text
    begin
        exit(ExecuteWebRequest(Url, Method, Request, ResponseHeaders, 5));
    end;

    /// <summary>
    /// ExecuteWebRequest.
    /// </summary>
    /// <param name="Url">Text.</param>
    /// <param name="Method">Text.</param>
    /// <param name="Request">Text.</param>
    /// <param name="ResponseHeaders">VAR HttpHeaders.</param>
    /// <param name="MaxRetries">Integer.</param>
    /// <returns>Return variable Response of type Text.</returns>
    internal procedure ExecuteWebRequest(Url: Text; Method: Text; Request: Text; var ResponseHeaders: HttpHeaders; MaxRetries: Integer) Response: Text
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        Wait: Duration;
        HttpClient: HttpClient;
        HttpRequestMessage: HttpRequestMessage;
        HttpResponseMessage: HttpResponseMessage;
        RetryCounter: Integer;
    begin
        FeatureTelemetry.LogUptake('0000HUV', 'Shopify', Enum::"Feature Uptake Status"::Used);
        FeatureTelemetry.LogUsage('0000IF5', 'Shopify', 'Shopify web request executed.');
        CheckOutgoingRequests(Url, Method, Request);

        CreateHttpRequestMessage(Url, Method, Request, HttpRequestMessage);

        Wait := 100;

        if Format(NextExecutionTime) = '' then
            NextExecutionTime := CurrentDateTime - Wait;

        if CurrentDateTime < (NextExecutionTime) then begin
            Wait := (NextExecutionTime - CurrentDateTime);
            if Wait > 0 then
                Sleep(Wait);
        end;

        if IsTestInProgress then
            CommunicationEvents.OnClientSend(HttpRequestMessage, HttpResponseMessage)
        else
            if HttpClient.Send(HttpRequestMessage, HttpResponseMessage) then begin
                Clear(RetryCounter);
                while (not HttpResponseMessage.IsBlockedByEnvironment) and (EvaluateResponse(HttpResponseMessage)) and (RetryCounter < MaxRetries) do begin
                    RetryCounter += 1;
                    Sleep(1000);
                    LogShopifyRequest(Url, Method, Request, HttpResponseMessage, Response, RetryCounter);
                    Clear(HttpClient);
                    Clear(HttpRequestMessage);
                    Clear(HttpResponseMessage);
                    CreateHttpRequestMessage(Url, Method, Request, HttpRequestMessage);
                    HttpClient.Send(HttpRequestMessage, HttpResponseMessage);
                end;
            end;
        if GetContent(HttpResponseMessage, Response) then;
        ResponseHeaders := HttpResponseMessage.Headers();
        LogShopifyRequest(Url, Method, Request, HttpResponseMessage, Response, RetryCounter);
        Commit();
    end;

    [TryFunction]
    local procedure GetContent(HttpResponseMsg: HttpResponseMessage; var Response: Text)
    begin
        if IsTestInProgress then
            CommunicationEvents.OnGetContent(HttpResponseMsg, Response)
        else
            HttpResponseMsg.Content.ReadAs(Response);
    end;

    /// <summary> 
    /// Get Id Of GId.
    /// </summary>
    /// <param name="GId">Parameter of type Text.</param>
    /// <returns>Return variable "Result" of type BigInteger.</returns>
    internal procedure GetIdOfGId(GId: Text) Result: BigInteger
    var
        Parts: List of [Text];
    begin
        GId.Split('?').Get(1, GId);
        Parts := GId.Split('/');
        GId := Parts.Get(Parts.Count);
        if Evaluate(Result, GId) then;
    end;

    /// <summary> 
    /// Set Shop.
    /// </summary>
    /// <param name="ShopifyShop">Parameter of type Record "Shopify Shop".</param>
    internal procedure SetShop(ShopifyShop: Record "Shpfy Shop")
    begin
        Shop := ShopifyShop;
    end;

    /// <summary> 
    /// Api Version.
    /// </summary>
    /// <returns>Return value of type Text.</returns>
    local procedure ApiVersion(): Text
    begin
        exit(VersionTok);
    end;

    /// <summary> 
    /// Description for ConvertToCleanOptionValue.
    /// </summary>
    /// <param name="Data">Parameter of type Text.</param>
    /// <returns>Return variable "Text".</returns>
    internal procedure ConvertToCleanOptionValue(Data: Text): Text
    var
        Words: List of [Text];
        Word: Text;
        Result: TextBuilder;
    begin
        Words := Data.Split('::');
        Words := Words.Get(Words.Count).Replace('_', ' ').Split(' ');
        foreach Word in Words do
            if Word <> '' then begin
                Result.Append(Word.Substring(1, 1).ToUpper());
                Result.Append(Word.Substring(2).ToLower());
                Result.Append(' ');
            end;
        exit(Result.ToText().TrimEnd());
    end;

    [NonDebuggable]
    /// <summary> 
    /// Create Http Request Message.
    /// </summary>
    /// <param name="Url">Parameter of type text.</param>
    /// <param name="Method">Parameter of type Text.</param>
    /// <param name="Request">Parameter of type Text.</param>
    /// <param name="HttpRequestMsg">Parameter of type HttpRequestMessage.</param>
    local procedure CreateHttpRequestMessage(Url: text; Method: Text; Request: Text; var HttpRequestMsg: HttpRequestMessage)
    var
        HttpContent: HttpContent;
        ContentHttpHeaders: HttpHeaders;
        HttpHeaders: HttpHeaders;
        AccessToken: Text;
    begin
        HttpRequestMsg.SetRequestUri(url);
        HttpRequestMsg.GetHeaders(HttpHeaders);


        if IsTestInProgress then
            CommunicationEvents.OnGetAccessToken(AccessToken)
        else
            AccessToken := Shop.GetAccessToken();

        HttpHeaders.Add('X-Shopify-Access-Token', AccessToken);
        HttpRequestMsg.Method := Method;

        if Method in ['POST', 'PUT'] then begin
            HttpContent.WriteFrom(Request);
            HttpContent.GetHeaders(ContentHttpHeaders);
            if ContentHttpHeaders.Contains('Content-Type') then
                ContentHttpHeaders.Remove('Content-Type');
            ContentHttpHeaders.Add('Content-Type', 'application/json');
            HttpRequestMsg.Content(HttpContent);
        end;
    end;

    /// <summary> 
    /// Create Shopify Log Entry.
    /// </summary>
    /// <param name="Url">Parameter of type text.</param>
    /// <param name="Method">Parameter of type text.</param>
    /// <param name="Request">Parameter of type Text.</param>
    /// <param name="HttpResponseMessage">Parameter of type HttpResponseMessage.</param>
    /// <param name="Response">Parameter of type text.</param>
    local procedure LogShopifyRequest(Url: Text; Method: Text; Request: Text; var HttpResponseMessage: HttpResponseMessage; Response: Text; RetryCount: Integer)
    begin
        case Shop."Logging Mode" of
            Shop."Logging Mode"::All:
                CreateShopifyLogEntry(Url, Method, Request, HttpResponseMessage, Response, RetryCount);
            Shop."Logging Mode"::"Error Only":
                if not HttpResponseMessage.IsSuccessStatusCode or Response.Contains('"errors":') or ResponseHasUserError(Response) then
                    CreateShopifyLogEntry(Url, Method, Request, HttpResponseMessage, Response, RetryCount);
        end;

        LogShopifyRequestTelemetry(Url, Method, HttpResponseMessage, RetryCount);
    end;

    local procedure CreateShopifyLogEntry(Url: text; Method: Text; Request: Text; var HttpResponseMessage: HttpResponseMessage; Response: Text; RetryCount: Integer)
    var
        ShopifyLogEntry: Record "Shpfy Log Entry";
        Values: array[10] of Text;
    begin
        ShopifyLogEntry.Init();
        ShopifyLogEntry."Date and Time" := CurrentDateTime;
        ShopifyLogEntry.Time := TIME;
        ShopifyLogEntry."User ID" := CopyStr(UserId, 1, MaxStrLen(ShopifyLogEntry."User ID"));
        ShopifyLogEntry.URL := CopyStr(Url, 1, MaxStrLen(ShopifyLogEntry.URL));
        ShopifyLogEntry.Method := CopyStr(Method, 1, MaxStrLen(ShopifyLogEntry.Method));
        ShopifyLogEntry."Status Code" := CopyStr(Format(HttpResponseMessage.HttpStatusCode), 1, MaxStrLen(ShopifyLogEntry."Status Code"));
        ShopifyLogEntry."Status Description" := CopyStr(HttpResponseMessage.ReasonPhrase, 1, MaxStrLen(ShopifyLogEntry."Status Description"));
        ShopifyLogEntry."Has Error" := not HttpResponseMessage.IsSuccessStatusCode or Response.Contains('"errors":') or ResponseHasUserError(Response);
        ShopifyLogEntry."Retry Count" := RetryCount;
        ShopifyLogEntry."Query Cost" := GetQueryCost(Response);
        if HttpResponseMessage.Headers().GetValues('X-Request-ID', Values) then
            if Evaluate(ShopifyLogEntry."Request Id", Values[1]) then;
        ShopifyLogEntry.Insert();
        if Request <> '' then
            ShopifyLogEntry.SetRequest(Request);
        if Response <> '' then
            ShopifyLogEntry.SetResponse(Response);
    end;

    local procedure ResponseHasUserError(Response: Text): Boolean;
    begin
        if Response.Contains('"userErrors":') then
            if not Response.Contains('"userErrors":[]') then
                exit(true);
    end;

    local procedure LogShopifyRequestTelemetry(Url: Text; Method: Text; var HttpResponseMessage: HttpResponseMessage; RetryCount: Integer)
    var
        CustomDimensions: Dictionary of [Text, Text];
        Values: array[10] of Text;
        RequestId: Text;
    begin
        CustomDimensions.Add('Category', CategoryTok);
        CustomDimensions.Add('Url', Url);
        CustomDimensions.Add('Response Code', Format(HttpResponseMessage.HttpStatusCode));
        CustomDimensions.Add('Retry Count', Format(RetryCount));
        if HttpResponseMessage.Headers().GetValues('X-Request-ID', Values) then
            RequestId := Values[1];
        Session.LogMessage('0000K8W', StrSubstNo(RequestTelemetryLbl, Method, RequestId), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, CustomDimensions);
    end;

    local procedure GetQueryCost(Response: Text): Integer
    var
        JsonHelper: Codeunit "Shpfy Json Helper";
        JResponse: JsonToken;
        Cost: Integer;
    begin
        if JResponse.ReadFrom(Response) then
            Cost := JsonHelper.GetValueAsDecimal(JsonHelper.GetJsonToken(JResponse, 'extensions.cost'), 'actualQueryCost');

        exit(Cost);
    end;

    internal procedure EscapeGrapQLData(Data: Text): Text
    begin
        exit(Data.Replace('\', '\\\\').Replace('"', '\\\"'));
    end;

    /// <summary> 
    /// Evaluate Response.
    /// </summary>
    /// <param name="HttpResponseMessage">Parameter of type HttpResponseMessage.</param>
    /// <returns>Return variable "Retry" of type Boolean.</returns>
    local procedure EvaluateResponse(HttpResponseMessage: HttpResponseMessage) Retry: Boolean
    var
        BucketPerc: Decimal;
        WaitTime: Duration;
        BucketSize: Integer;
        BucketUse: Integer;
        Status: Integer;
        Values: array[10] of Text;
    begin
        Status := HttpResponseMessage.HttpStatusCode();
        case Status of
            429:
                begin
                    Sleep(2000);
                    Retry := true;
                end;
            500 .. 599:
                begin
                    Sleep(10000);
                    Retry := true;
                end;
            else
                if HttpResponseMessage.Headers().GetValues('X-Shopify-Shop-Api-Call-Limit', Values) then
                    if Evaluate(BucketUse, Values[1].Split('/').Get(1)) and Evaluate(BucketSize, Values[1].Split('/').Get(2)) then begin
                        BucketPerc := 100 * BucketUse / BucketSize;
                        if BucketPerc >= 90 then
                            WaitTime := 1000
                        else
                            if BucketPerc >= 80 then
                                WaitTime := 800
                            else
                                if BucketPerc >= 70 then
                                    WaitTime := 600
                                else
                                    if BucketPerc >= 60 then
                                        WaitTime := 400
                                    else
                                        if BucketPerc >= 50 then
                                            WaitTime := 200;
                    end;
                NextExecutionTime := CurrentDateTime() + WaitTime;
        end;
    end;

    /// <summary> 
    /// Description for SetShop.
    /// </summary>
    /// <param name="ShopCode">Parameter of type Code[20].</param>
    internal procedure SetShop(ShopCode: Code[20])
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        Clear(Shop);
        Shop.Get(ShopCode);
        FeatureTelemetry.LogUsage('0000JW7', 'Shopify', Format(Shop."Shop Id"));
    end;

    /// <summary>
    /// SetTestInProgress.
    /// </summary>
    /// <param name="TestInProgress">Boolean.</param>
    [NonDebuggable]
    internal procedure SetTestInProgress(TestInProgress: Boolean)
    begin
        IsTestInProgress := TestInProgress;
    end;

    [NonDebuggable]
    internal procedure GetTestInProgress(): Boolean
    begin
        exit(IsTestInProgress);
    end;

    [NonDebuggable]
    internal procedure GetVersion(): Text
    begin
        exit(VersionTok);
    end;

    [NonDebuggable]
    internal procedure GetShopRecord() ShopifyShop: Record "Shpfy Shop";
    begin
        if not ShopifyShop.Get(Shop.Code) then
            Clear(ShopifyShop);
    end;

    internal procedure CheckOutgoingRequests(Url: Text; Method: Text; Request: Text)
    begin
        if Method in ['POST', 'PUT'] then begin
            if Request.Contains('"query"') then
                if not Request.Contains('"mutation') then
                    exit;

            if not Shop."Allow Outgoing Requests" then
                if GuiAllowed then begin
                    if Confirm(OutgoingRequestsNotEnabledConfirmLbl) then
                        Page.Run(Page::"Shpfy Shop Card", Shop);
                    Error('');
                end else
                    Error(OutgoingRequestsNotEnabledErr);
        end;
    end;

    local procedure CheckQueryLength(GraphQLQuery: Text)
    begin
        if StrLen(GraphQLQuery) > 50000 then begin
            Session.LogMessage('0000K18', QueryParamTooLongTxt, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
            if GraphQLQuery.Contains('productCreate') then
                Error(ProductCreateQueryParamTooLongErr);
            Error(QueryParamTooLongErr);
        end;
    end;
}

