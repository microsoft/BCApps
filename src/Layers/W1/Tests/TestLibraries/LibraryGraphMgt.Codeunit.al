codeunit 130618 "Library - Graph Mgt"
{

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        Authentication: Enum "API Test Authentication";
        AuthenticationProvider: Interface "API Test Auth Provider";
        AuthenticationProviderResolved: Boolean;
        IncorrectValueErr: Label 'Incorrect value found in JSON for %1 property.', Comment = '%1 - Name of property';
        GraphCollectionMgtItem: Codeunit "Graph Collection Mgt - Item";
        UnexpectedResponseCodeErr: Label 'Response code %1 (%2) differs from the expected %3.', Comment = '%1 - Actual response code number, %2 - Actual response code, %3 - Expected response code number';
        FailedRequestErr: Label '%1 request failed. Response code is %2 (%3). %4', Comment = '%1 - request method, %2 - response code number, %3 - response code, %4 - error message';
        FailedRequestWithUnexpectedResponseCodeErr: Label '%1 request failed. Response code is %2 (%3), expected code is %4. %5', Comment = '%1 - request method, %2 - response code number, %3 - response code, %4 - expected response code, %5 - error message';
        RemoteServerErr: Label 'The remote server returned an error: (%1) %2.', Comment = '%1 - response code number, %2 - reason phrase';
        JsonContentTypeTok: Label 'application/json;odata.metadata=minimal', Locked = true;

    /// <summary>
    /// Sets the authentication provider used by this library instance.
    /// Selecting the same provider preserves its cached state.
    /// </summary>
    /// <param name="NewAuthentication">The authentication provider to use for subsequent API test requests.</param>
    procedure SetAuthenticationProvider(NewAuthentication: Enum "API Test Authentication")
    begin
        if AuthenticationProviderResolved and (Authentication = NewAuthentication) then
            exit;

        Authentication := NewAuthentication;
        AuthenticationProvider := Authentication;
        AuthenticationProviderResolved := true;
    end;

    procedure EnsureWebServiceExist(ServiceNameTxt: Text[240]; PageNumber: Integer)
    var
        WebService: Record "Web Service";
    begin
        WebService.LockTable();

        if WebService.Get(WebService."Object Type"::Page, ServiceNameTxt) then begin
            WebService.Validate("Object ID", PageNumber);
            WebService.Validate(Published, true);
            WebService.Modify();
        end else begin
            WebService.Validate("Object Type", WebService."Object Type"::Page);
            WebService.Validate("Object ID", PageNumber);
            WebService.Validate("Service Name", ServiceNameTxt);
            WebService.Validate(Published, true);
            if WebService.Insert() then;
        end;

        Commit();
    end;

    procedure UnpublishWebService(ServiceNameTxt: Text; PageNumber: Integer)
    var
        WebService: Record "Web Service";
    begin
        WebService.SetRange("Object Type", WebService."Object Type"::Page);
        WebService.SetRange("Object ID", PageNumber);
        WebService.SetRange("Service Name", ServiceNameTxt);
        WebService.FindFirst();

        WebService.Validate(Published, false);
        WebService.Modify(true);
    end;

    procedure GetFromWebServiceAndCheckResponseCode(var ResponseText: Text; TargetURL: Text; ExpectedResponseCode: Integer)
    var
        HttpRequestMessage: HttpRequestMessage;
    begin
        InitializeWebRequestWithURL(HttpRequestMessage, TargetURL);
        HttpRequestMessage.Method('GET');
        SetRequestHeader(HttpRequestMessage, 'Accept', 'application/json');

        GetTextResponseAndCheckForErrors(HttpRequestMessage, ResponseText, ExpectedResponseCode);
    end;

    procedure GetBinaryFromWebServiceAndCheckResponseCode(var TempBlob: Codeunit "Temp Blob"; TargetURL: Text; ReturnType: Text; ExpectedResponseCode: Integer)
    var
        HttpRequestMessage: HttpRequestMessage;
    begin
        InitializeWebRequestWithURL(HttpRequestMessage, TargetURL);
        HttpRequestMessage.Method('GET');
        SetRequestHeader(HttpRequestMessage, 'Accept', ReturnType);

        GetResponseAndCheckForErrors(HttpRequestMessage, TempBlob, ExpectedResponseCode);
    end;

    procedure PostToWebServiceAndCheckResponseCode(TargetURL: Text; JSONBody: Text; var ResponseText: Text; ExpectedResponseCode: Integer)
    var
        HttpRequestMessage: HttpRequestMessage;
    begin
        InitializeWebRequestWithURL(HttpRequestMessage, TargetURL);
        SetRequestHeader(HttpRequestMessage, 'Accept', 'application/json');
        HttpRequestMessage.Method('POST');
        SetTextContent(HttpRequestMessage, JSONBody, JsonContentTypeTok);

        GetTextResponseAndCheckForErrors(HttpRequestMessage, ResponseText, ExpectedResponseCode);
    end;

    procedure PostToWebServiceAndCheckResponseCodeExtended(TargetURL: Text; JSONBody: Text; var ResponseText: Text; var ResponseHeaders: Dictionary of [Text, Text]; ExpectedResponseCode: Integer)
    var
        HttpRequestMessage: HttpRequestMessage;
    begin
        InitializeWebRequestWithURL(HttpRequestMessage, TargetURL);
        SetRequestHeader(HttpRequestMessage, 'Accept', 'application/json');
        HttpRequestMessage.Method('POST');
        SetTextContent(HttpRequestMessage, JSONBody, JsonContentTypeTok);

        GetTextResponseAndCheckForErrorsExtended(HttpRequestMessage, ResponseText, ResponseHeaders, ExpectedResponseCode);
    end;

    local procedure UpdateToWebServiceAndCheckResponseCode(TargetURL: Text; JSONBody: Text; Method: Text; var ResponseText: Text; ExpectedResponseCode: Integer)
    var
        HttpRequestMessage: HttpRequestMessage;
        ETag: Text;
    begin
        ETag := GetEtag(TargetURL);

        InitializeWebRequestWithURL(HttpRequestMessage, TargetURL);
        SetRequestHeader(HttpRequestMessage, 'Accept', 'application/json');
        HttpRequestMessage.Method(Method);
        SetRequestHeader(HttpRequestMessage, 'If-Match', ETag);
        SetTextContent(HttpRequestMessage, JSONBody, JsonContentTypeTok);

        GetTextResponseAndCheckForErrors(HttpRequestMessage, ResponseText, ExpectedResponseCode);
    end;

    procedure BinaryUpdateToWebServiceAndCheckResponseCode(TargetURL: Text; var TempBlob: Codeunit "Temp Blob"; Method: Text; var ResponseText: Text; ExpectedResponseCode: Integer)
    var
        HttpRequestMessage: HttpRequestMessage;
        ETag: Text;
    begin
        ETag := '*';

        InitializeWebRequestWithURL(HttpRequestMessage, TargetURL);
        SetRequestHeader(HttpRequestMessage, 'Accept', 'application/json');
        SetRequestHeader(HttpRequestMessage, 'If-Match', ETag);
        HttpRequestMessage.Method(Method);
        SetBlobContent(HttpRequestMessage, TempBlob, 'application/octet-stream');

        GetTextResponseAndCheckForErrors(HttpRequestMessage, ResponseText, ExpectedResponseCode);
    end;

    /// <summary>
    /// Initializes an HTTP request for the target URL and applies the configured API test authentication.
    /// </summary>
    /// <param name="HttpRequestMessage">The request to initialize.</param>
    /// <param name="TargetURL">The URL the request is sent to.</param>
    procedure InitializeWebRequestWithURL(var HttpRequestMessage: HttpRequestMessage; TargetURL: Text)
    begin
        Clear(HttpRequestMessage);
        HttpRequestMessage.Method('GET');
        HttpRequestMessage.SetRequestUri(TargetURL);
        ApplyAuthentication(HttpRequestMessage);
        OnAfterInitializeWebRequestWithURL(HttpRequestMessage);
    end;

    local procedure ApplyAuthentication(var HttpRequestMessage: HttpRequestMessage)
    var
        AuthenticationContext: Codeunit "API Test Auth Context";
        CurrentAuthenticationProvider: Interface "API Test Auth Provider";
    begin
        CurrentAuthenticationProvider := GetAuthenticationProvider();
        CurrentAuthenticationProvider.ConfigureAuthentication(AuthenticationContext);
        AuthenticationContext.Apply(HttpRequestMessage);
    end;

    local procedure SetRequestHeader(var HttpRequestMessage: HttpRequestMessage; HeaderName: Text; HeaderValue: Text)
    var
        RequestHeaders: HttpHeaders;
    begin
        HttpRequestMessage.GetHeaders(RequestHeaders);
        if RequestHeaders.Contains(HeaderName) then
            RequestHeaders.Remove(HeaderName);
        RequestHeaders.Add(HeaderName, HeaderValue);
    end;

    local procedure SetTextContent(var HttpRequestMessage: HttpRequestMessage; Body: Text; ContentType: Text)
    var
        HttpContent: HttpContent;
    begin
        HttpContent.WriteFrom(Body);
        SetContent(HttpRequestMessage, HttpContent, ContentType);
    end;

    local procedure SetBlobContent(var HttpRequestMessage: HttpRequestMessage; var TempBlob: Codeunit "Temp Blob"; ContentType: Text)
    var
        HttpContent: HttpContent;
        BodyInStream: InStream;
    begin
        if TempBlob.HasValue() then begin
            TempBlob.CreateInStream(BodyInStream);
            HttpContent.WriteFrom(BodyInStream);
        end;
        SetContent(HttpRequestMessage, HttpContent, ContentType);
    end;

    local procedure SetContent(var HttpRequestMessage: HttpRequestMessage; var HttpContent: HttpContent; ContentType: Text)
    var
        ContentHeaders: HttpHeaders;
    begin
        HttpContent.GetHeaders(ContentHeaders);
        if ContentHeaders.Contains('Content-Type') then
            ContentHeaders.Remove('Content-Type');
        ContentHeaders.Add('Content-Type', ContentType);
        HttpRequestMessage.Content := HttpContent;
    end;

    local procedure GetAuthenticationProvider(): Interface "API Test Auth Provider"
    begin
        if not AuthenticationProviderResolved then begin
            AuthenticationProvider := Authentication;
            AuthenticationProviderResolved := true;
        end;

        exit(AuthenticationProvider);
    end;

    procedure PatchToWebServiceAndCheckResponseCode(TargetURL: Text; JSONBody: Text; var ResponseText: Text; ExpectedResponseCode: Integer)
    begin
        UpdateToWebServiceAndCheckResponseCode(TargetURL, JSONBody, 'PATCH', ResponseText, ExpectedResponseCode);
    end;

    procedure DeleteFromWebServiceAndCheckResponseCode(TargetURL: Text; JSONBody: Text; var ResponseText: Text; ExpectedResponseCode: Integer)
    begin
        UpdateToWebServiceAndCheckResponseCode(TargetURL, JSONBody, 'DELETE', ResponseText, ExpectedResponseCode);
    end;

    procedure GetFromWebService(var ResponseText: Text; TargetURL: Text)
    begin
        GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);
    end;

    procedure PostToWebService(TargetURL: Text; JSONBody: Text; var ResponseText: Text)
    begin
        PostToWebServiceAndCheckResponseCode(TargetURL, JSONBody, ResponseText, 201);
    end;

    procedure PatchToWebService(TargetURL: Text; JSONBody: Text; var ResponseText: Text)
    begin
        PatchToWebServiceAndCheckResponseCode(TargetURL, JSONBody, ResponseText, 200);
    end;

    procedure DeleteFromWebService(TargetURL: Text; JSONBody: Text; var ResponseText: Text)
    begin
        DeleteFromWebServiceAndCheckResponseCode(TargetURL, JSONBody, ResponseText, 204);
    end;

    local procedure GetEtag(TargetURL: Text): Text
    var
        ResponseText: Text;
        ETag: Text;
    begin
        GetFromWebService(ResponseText, TargetURL);
        GetETagFromJSON(ResponseText, ETag);
        Assert.AreNotEqual('', ETag, 'ETag should not be empty');
        exit(ETag);
    end;

    [Normal]
    procedure CreateTargetURL(ID: Text; PageNumber: Integer; ServiceNameTxt: Text): Text
    var
        TargetURL: Text;
        ReplaceWith: Text;
    begin
        TargetURL := GetODataTargetURL(ObjectType::Page, PageNumber);
        if ID <> '' then begin
            ReplaceWith := StrSubstNo('%1(%2)', ServiceNameTxt, StripBrackets(ID));
            TargetURL := STRREPLACE(TargetURL, ServiceNameTxt, ReplaceWith);
        end;
        exit(TargetURL);
    end;

    [Normal]
    procedure CreateQueryTargetURL(QueryNumber: Integer; ServiceNameTxt: Text): Text
    var
        TargetURL: Text;
    begin
        TargetURL := GetODataTargetURL(ObjectType::Query, QueryNumber);
        TargetURL += ServiceNameTxt;
        exit(TargetURL);
    end;

    [Normal]
    procedure CreateTargetURLWithSubpage(ID: Text; PageNumber: Integer; ServiceNameTxt: Text; ServiceSubPageTxt: Text): Text
    var
        TargetURL: Text;
    begin
        TargetURL := GetODataTargetURL(ObjectType::Page, PageNumber);
        exit(AppendSubpageToTargetURL(ID, TargetURL, ServiceNameTxt, ServiceSubPageTxt));
    end;

    [Normal]
    procedure CreateTargetURLWithTwoKeyFields(ID1: Text; ID2: Text; PageNumber: Integer; ServiceNameTxt: Text): Text
    var
        TargetURL: Text;
        ReplaceWith: Text;
    begin
        TargetURL := GetODataTargetURL(ObjectType::Page, PageNumber);
        if (ID1 <> '') and (ID2 <> '') then begin
            ReplaceWith := StrSubstNo('%1(%2,%3)', ServiceNameTxt, StripBrackets(ID1), StripBrackets(ID2));
            TargetURL := STRREPLACE(TargetURL, ServiceNameTxt, ReplaceWith);
        end;
        exit(TargetURL);
    end;

    [Normal]
    procedure CreateTargetURLWithTwoKeyFieldsAndSubpage(ID1: Text; ID2: Text; PageNumber: Integer; ServiceNameTxt: Text; ServiceSubPageTxt: Text): Text
    var
        TargetURL: Text;
    begin
        TargetURL := GetODataTargetURL(ObjectType::Page, PageNumber);
        exit(AppendSubpageToTargetURLWithTwoKeyFields(ID1, ID2, TargetURL, ServiceNameTxt, ServiceSubPageTxt));
    end;

    [Normal]
    procedure AppendSubpageToTargetURL(ID: Text; TargetURL: Text; ServiceNameTxt: Text; ServiceSubPageTxt: Text): Text
    var
        ReplaceWith: Text;
    begin
        if ServiceSubPageTxt <> '' then begin
            ReplaceWith := StrSubstNo('%1/%2', ServiceNameTxt, ServiceSubPageTxt);
            TargetURL := STRREPLACE(TargetURL, ServiceNameTxt, ReplaceWith);
        end;
        if ID <> '' then begin
            ReplaceWith := StrSubstNo('%1(%2)', ServiceNameTxt, StripBrackets(ID));
            TargetURL := STRREPLACE(TargetURL, ServiceNameTxt, ReplaceWith);
        end;
        exit(TargetURL);
    end;

    [Normal]
    procedure AppendSubpageToTargetURLWithTwoKeyFields(ID1: Text; ID2: Text; TargetURL: Text; ServiceNameTxt: Text; ServiceSubPageTxt: Text): Text
    var
        ReplaceWith: Text;
    begin
        if ServiceSubPageTxt <> '' then begin
            ReplaceWith := StrSubstNo('%1/%2', ServiceNameTxt, ServiceSubPageTxt);
            TargetURL := STRREPLACE(TargetURL, ServiceNameTxt, ReplaceWith);
        end;
        if (ID1 <> '') and (ID2 <> '') then begin
            ReplaceWith := StrSubstNo('%1(%2,%3)', ServiceNameTxt, StripBrackets(ID1), StripBrackets(ID2));
            TargetURL := STRREPLACE(TargetURL, ServiceNameTxt, ReplaceWith);
        end;
        exit(TargetURL);
    end;

    [Normal]
    procedure CreateSubpageURL(ID: Text; ParentPagePageNumber: Integer; ParentPageServiceNameTxt: Text; SubpageServiceNameTxt: Text): Text
    var
        TargetURL: Text;
        ReplaceWith: Text;
    begin
        TargetURL := GetODataTargetURL(ObjectType::Page, ParentPagePageNumber);

        TargetURL := STRREPLACE(TargetURL, ParentPageServiceNameTxt, SubpageServiceNameTxt);

        if ID <> '' then begin
            ReplaceWith := StrSubstNo('%1(%2)', SubpageServiceNameTxt, StripBrackets(ID));
            TargetURL := STRREPLACE(TargetURL, SubpageServiceNameTxt, ReplaceWith);
        end;

        exit(TargetURL);
    end;

    /// <summary>Appends a path before any query string in an API target URL.</summary>
    /// <param name="TargetURL">API target URL.</param>
    /// <param name="Path">Path to append.</param>
    /// <returns>The URL with the appended path.</returns>
    procedure AppendPathToTargetURL(TargetURL: Text; Path: Text): Text
    var
        QueryPosition: Integer;
    begin
        QueryPosition := StrPos(TargetURL, '?');
        if QueryPosition = 0 then
            exit(TargetURL + Path);

        exit(CopyStr(TargetURL, 1, QueryPosition - 1) + Path + CopyStr(TargetURL, QueryPosition));
    end;

    /// <summary>Appends a query parameter using the appropriate query separator.</summary>
    /// <param name="TargetURL">API target URL.</param>
    /// <param name="QueryParameter">Query parameter to append.</param>
    /// <returns>The URL with the appended query parameter.</returns>
    procedure AppendQueryParameterToTargetURL(TargetURL: Text; QueryParameter: Text): Text
    begin
        if StrPos(TargetURL, '?') = 0 then
            exit(TargetURL + '?' + QueryParameter);

        exit(TargetURL + '&' + QueryParameter);
    end;

    [Normal]
    procedure STRREPLACE(String: Text; ReplaceWhat: Text; ReplaceWith: Text): Text
    var
        Pos: Integer;
    begin
        Pos := StrPos(String, ReplaceWhat);
        if Pos > 0 then
            String := DelStr(String, Pos) + ReplaceWith + CopyStr(String, Pos + StrLen(ReplaceWhat));
        exit(String);
    end;

    local procedure ExecuteWebRequestAndReadTextResponse(var HttpRequestMessage: HttpRequestMessage; var ResponseText: Text; var ResponseError: Text; var ResponseStatusCode: Integer; var ResponseStatusName: Text; var ResponseHeaders: Dictionary of [Text, Text]): Boolean
    var
        TempBlob: Codeunit "Temp Blob";
        Successful: Boolean;
    begin
        Successful := ExecuteWebRequestAndReadResponse(HttpRequestMessage, TempBlob, ResponseError, ResponseStatusCode, ResponseStatusName, ResponseHeaders);
        if Successful then
            ResponseText += ReadTextFromTempBlob(TempBlob);

        exit(Successful);
    end;

    local procedure ExecuteWebRequestAndReadResponse(var HttpRequestMessage: HttpRequestMessage; var TempBlob: Codeunit "Temp Blob"; var ResponseError: Text; var ResponseStatusCode: Integer; var ResponseStatusName: Text; var ResponseHeaders: Dictionary of [Text, Text]): Boolean
    var
        HttpClient: HttpClient;
        HttpResponseMessage: HttpResponseMessage;
        RequestHeaders: HttpHeaders;
        ContentHeaders: HttpHeaders;
        HttpResponseInStream: InStream;
        ResponseOutStream: OutStream;
        LastError: Text;
        ErrorCode: Text;
        ErrorMessage: Text;
    begin
        Clear(TempBlob);
        ResponseStatusCode := 0;
        ResponseStatusName := '';
        Clear(ResponseHeaders);

        ClearLastError();
        OnExecuteWebRequestAndReadResponseOnBeforeGetResponse(HttpRequestMessage);

        // API tests call the local Business Central server, which may require Windows authentication.
        // Explicit authentication (for example Basic) configured on the request takes precedence.
        HttpRequestMessage.GetHeaders(RequestHeaders);
        if not (RequestHeaders.Contains('Authorization') or RequestHeaders.ContainsSecret('Authorization')) then
            HttpClient.UseDefaultNetworkWindowsAuthentication();
        HttpClient.Timeout(60000);

        if not HttpClient.Send(HttpRequestMessage, HttpResponseMessage) then begin
            ResponseError := GetLastErrorText();
            exit(false);
        end;

        ResponseStatusCode := HttpResponseMessage.HttpStatusCode();
        ResponseStatusName := GetStatusName(HttpResponseMessage);
        HttpResponseMessage.Content.GetHeaders(ContentHeaders);
        AddHeadersToDictionary(ResponseHeaders, HttpResponseMessage.Headers());
        AddHeadersToDictionary(ResponseHeaders, ContentHeaders);

        HttpResponseMessage.Content.ReadAs(HttpResponseInStream);
        TempBlob.CreateOutStream(ResponseOutStream);
        CopyStream(ResponseOutStream, HttpResponseInStream);

        if HttpResponseMessage.IsSuccessStatusCode() then
            exit(true);

        LastError := StrSubstNo(RemoteServerErr, ResponseStatusCode, GetReasonPhrase(HttpResponseMessage, ResponseStatusName));
        ResponseError := LastError;

        if not GetErrorFromJSONResponse(ReadTextFromTempBlob(TempBlob), ErrorCode, ErrorMessage) then
            exit(false);

        ResponseError := '';
        if ErrorCode <> '' then
            ResponseError += STRREPLACE(StrSubstNo('Error code: %1. ', ErrorCode), '..', '.');
        if ErrorMessage <> '' then
            ResponseError += STRREPLACE(StrSubstNo('Error message: %1. ', ErrorMessage), '..', '.');
        ResponseError += LastError;
        exit(false);
    end;

    local procedure ReadTextFromTempBlob(var TempBlob: Codeunit "Temp Blob") Result: Text
    var
        ResponseInStream: InStream;
        ResponseTextBuilder: TextBuilder;
        TextLine: Text;
    begin
        TempBlob.CreateInStream(ResponseInStream);
        while ResponseInStream.ReadText(TextLine) > 0 do
            ResponseTextBuilder.Append(TextLine);

        exit(ResponseTextBuilder.ToText());
    end;

    local procedure AddHeadersToDictionary(var ResponseHeaders: Dictionary of [Text, Text]; Headers: HttpHeaders)
    var
        HeaderValues: array[50] of Text;
        HeaderName: Text;
        HeaderValue: Text;
        Index: Integer;
    begin
        foreach HeaderName in Headers.Keys() do begin
            Clear(HeaderValues);
            Headers.GetValues(HeaderName, HeaderValues);
            HeaderValue := '';
            for Index := 1 to ArrayLen(HeaderValues) do
                if HeaderValues[Index] <> '' then
                    if HeaderValue = '' then
                        HeaderValue := HeaderValues[Index]
                    else
                        HeaderValue += ',' + HeaderValues[Index];
            ResponseHeaders.Set(HeaderName, HeaderValue);
        end;
    end;

    local procedure GetStatusName(var HttpResponseMessage: HttpResponseMessage): Text
    var
        StatusName: Text;
    begin
        // Tests assert on the System.Net.HttpStatusCode names (for example 'BadRequest'), so map the code
        // instead of relying on the reason phrase, which is empty over HTTP/2 and may differ from the enum name.
        case HttpResponseMessage.HttpStatusCode() of
            200:
                exit('OK');
            201:
                exit('Created');
            202:
                exit('Accepted');
            204:
                exit('NoContent');
            304:
                exit('NotModified');
            400:
                exit('BadRequest');
            401:
                exit('Unauthorized');
            403:
                exit('Forbidden');
            404:
                exit('NotFound');
            405:
                exit('MethodNotAllowed');
            406:
                exit('NotAcceptable');
            408:
                exit('RequestTimeout');
            409:
                exit('Conflict');
            410:
                exit('Gone');
            411:
                exit('LengthRequired');
            412:
                exit('PreconditionFailed');
            413:
                exit('RequestEntityTooLarge');
            415:
                exit('UnsupportedMediaType');
            416:
                exit('RequestedRangeNotSatisfiable');
            422:
                exit('UnprocessableEntity');
            428:
                exit('PreconditionRequired');
            429:
                exit('TooManyRequests');
            500:
                exit('InternalServerError');
            501:
                exit('NotImplemented');
            502:
                exit('BadGateway');
            503:
                exit('ServiceUnavailable');
            504:
                exit('GatewayTimeout');
        end;

        StatusName := DelChr(HttpResponseMessage.ReasonPhrase(), '=', ' -');
        if StatusName = '' then
            StatusName := Format(HttpResponseMessage.HttpStatusCode());
        exit(StatusName);
    end;

    local procedure GetReasonPhrase(var HttpResponseMessage: HttpResponseMessage; StatusName: Text): Text
    begin
        if HttpResponseMessage.ReasonPhrase() <> '' then
            exit(HttpResponseMessage.ReasonPhrase());
        exit(StatusName);
    end;

    procedure GetODataTargetURL(ObjType: ObjectType; ObjectNumber: Integer): Text
    var
        ApiWebService: Record "Api Web Service";
        WebServiceAggregate: Record "Web Service Aggregate";
        WebServiceManagement: Codeunit "Web Service Management";
        WebServiceClientType: Enum "Client Type";
        ApiWebServiceObjectType: Option;
        WebServiceAggregateObjectType: Option;
        OdataUrl: Text;
    begin
        if ObjType = OBJECTTYPE::Page then begin
            ApiWebServiceObjectType := ApiWebService."Object Type"::Page;
            WebServiceAggregateObjectType := WebServiceAggregate."Object Type"::Page;
        end else begin
            ApiWebServiceObjectType := ApiWebService."Object Type"::Query;
            WebServiceAggregateObjectType := WebServiceAggregate."Object Type"::Query;
        end;

        ApiWebService.SetRange(Published, true);
        ApiWebService.SetRange("Object ID", ObjectNumber);
        ApiWebService.SetRange("Object Type", ApiWebServiceObjectType);
        if ApiWebService.FindFirst() then begin
            OdataUrl := GetUrl(CLIENTTYPE::Api, CompanyName, ObjType, ObjectNumber);
            exit(OdataUrl);
        end;
        WebServiceManagement.LoadRecords(WebServiceAggregate);
        WebServiceAggregate.SetRange(Published, true);
        WebServiceAggregate.SetRange("Object ID", ObjectNumber);
        WebServiceAggregate.SetRange("Object Type", WebServiceAggregateObjectType);
        WebServiceAggregate.FindFirst();
        OdataUrl := WebServiceManagement.GetWebServiceUrl(WebServiceAggregate, WebServiceClientType::ODataV4);
        exit(OdataUrl);
    end;

    procedure GetETagFromJSON(JSONTxt: Text; var ETagValue: Text): Boolean
    var
        JSONManagement: Codeunit "JSON Management";
        JObject: DotNet JObject;
    begin
        JSONManagement.InitializeObject(JSONTxt);
        JSONManagement.GetJSONObject(JObject);
        exit(JSONManagement.GetStringPropertyValueFromJObjectByName(JObject, '@odata.etag', ETagValue));
    end;

    procedure AddPropertytoJSON(JSONTxt: Text; PropertyName: Text; PropertyValue: Variant): Text
    var
        JSONManagement: Codeunit "JSON Management";
        JsonObject: DotNet JObject;
    begin
        JSONManagement.InitializeObject(JSONTxt);
        JSONManagement.GetJSONObject(JsonObject);

        JSONManagement.AddJPropertyToJObject(JsonObject, PropertyName, PropertyValue);
        exit(JSONManagement.WriteObjectToString());
    end;

    procedure AddComplexTypetoJSON(JSONTxt: Text; ComplexTypeName: Text; ComplexTypeValue: Text): Text
    var
        JSONManagement: Codeunit "JSON Management";
        JsonObject: DotNet JObject;
    begin
        JSONManagement.InitializeObject(JSONTxt);
        JSONManagement.GetJSONObject(JsonObject);

        JSONManagement.AddJObjectToJObject(JsonObject, ComplexTypeName, ComplexTypeValue);
        exit(JSONManagement.WriteObjectToString());
    end;

    procedure AddObjectToCollectionJSON(JSONTxt: Text; ObjectJSONTxt: Text): Text
    var
        JSONManagement: Codeunit "JSON Management";
        JSONObject: DotNet JObject;
    begin
        JSONManagement.InitializeCollection(JSONTxt);
        JSONManagement.InitializeObject(ObjectJSONTxt);
        JSONManagement.GetJSONObject(JSONObject);
        JSONManagement.AddJObjectToCollection(JSONObject);
        exit(JSONManagement.WriteCollectionToString());
    end;

    [Scope('OnPrem')]
    procedure AssertPropertyInJsonObject(JObject: DotNet JObject; PropertyName: Text; ExpectedValue: Text)
    var
        JsonMgt: Codeunit "JSON Management";
        PropertyValue: Text;
    begin
        JsonMgt.GetStringPropertyValueFromJObjectByName(JObject, PropertyName, PropertyValue);
        Assert.AreEqual(ExpectedValue, PropertyValue, StrSubstNo(IncorrectValueErr, PropertyName));
    end;

    procedure CreateSimpleTemplateSelectionRule(var ConfigTmplSelectionRules: Record "Config. Tmpl. Selection Rules"; PageID: Integer; TableID: Integer; RuleField: Integer; RuleFieldValue: Variant; TemplateField: Integer; TemplateValue: Variant)
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        ConfigTemplateLine: Record "Config. Template Line";
        LibraryRapidStart: Codeunit "Library - Rapid Start";
    begin
        LibraryRapidStart.CreateConfigTemplateHeader(ConfigTemplateHeader);
        ConfigTemplateHeader."Table ID" := TableID;
        ConfigTemplateHeader.Modify();

        LibraryRapidStart.CreateConfigTemplateLine(ConfigTemplateLine, ConfigTemplateHeader.Code);
        ConfigTemplateLine."Field ID" := TemplateField;
        ConfigTemplateLine."Default Value" := TemplateValue;
        ConfigTemplateLine.Modify(true);

        LibraryRapidStart.CreateTemplateSelectionRule(ConfigTmplSelectionRules, RuleField, RuleFieldValue, 1, PageID, ConfigTemplateHeader);
        ConfigTmplSelectionRules.Order := 0;
        ConfigTmplSelectionRules.Modify(true);
        Commit(); // Must commit in order for templates to get used in next web service call.
    end;

    [Scope('OnPrem')]
    procedure GetPropertyValueFromJSON(JSON: Text; PropertyName: Text; var PropertyValue: Text): Boolean
    var
        JsonMgt: Codeunit "JSON Management";
        JsonObject: DotNet JObject;
        PropertyValueVar: Variant;
    begin
        JsonMgt.InitializeObject(JSON);
        JsonMgt.GetJSONObject(JsonObject);
        if JsonMgt.GetPropertyValueByName(PropertyName, PropertyValueVar) = false then
            exit(false);
        PropertyValue := Format(PropertyValueVar);
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure GetComplexPropertyFromJSON(JSON: Text; PropertyName: Text; var JObject: DotNet JObject)
    var
        JsonMgt: Codeunit "JSON Management";
        ParentObject: DotNet JObject;
        ComplexText: Text;
    begin
        JsonMgt.InitializeObject(JSON);
        JsonMgt.GetJSONObject(ParentObject);

        JsonMgt.GetStringPropertyValueFromJObjectByName(ParentObject, PropertyName, ComplexText);
        JsonMgt.InitializeObject(ComplexText);
        JsonMgt.GetJSONObject(JObject);
    end;

    [Scope('OnPrem')]
    procedure GetComplexPropertyTxtFromJSON(JSON: Text; PropertyName: Text; var ComplexText: Text): Boolean
    var
        JsonMgt: Codeunit "JSON Management";
        ParentObject: DotNet JObject;
        ComplexTxtVar: Variant;
    begin
        JsonMgt.InitializeObject(JSON);
        JsonMgt.GetJSONObject(ParentObject);
        if JsonMgt.GetStringPropertyValueFromJObjectByName(ParentObject, PropertyName, ComplexTxtVar) = false then
            exit(false);
        ComplexText := Format(ComplexTxtVar);
        exit(true);
    end;

    procedure GetObjectFromJSONResponse(ResponseText: Text; var ObjectJSON: Text; ObjectNumber: Integer): Boolean
    begin
        exit(GetObjectFromJSONResponseByName(ResponseText, 'value', ObjectJSON, ObjectNumber));
    end;

    procedure GetObjectFromJSONResponseByName(ResponseText: Text; PropertyName: Text; var ObjectJSON: Text; ObjectNumber: Integer): Boolean
    var
        JSONManagement: Codeunit "JSON Management";
        JSONObject: DotNet JObject;
        JObject: DotNet JObject;
        ObjectCollectionTxt: Text;
    begin
        JSONManagement.InitializeObject(ResponseText);
        JSONManagement.GetJSONObject(JSONObject);
        JSONManagement.GetStringPropertyValueFromJObjectByName(JSONObject, PropertyName, ObjectCollectionTxt);
        Clear(JSONManagement);
        JSONManagement.InitializeCollection(ObjectCollectionTxt);

        Assert.IsTrue(
          JSONManagement.GetCollectionCount() >= ObjectNumber, StrSubstNo('At least %1 item(s) should be returned', ObjectNumber));
        if not JSONManagement.GetJObjectFromCollectionByIndex(JObject, ObjectNumber - 1) then
            exit(false);
        ObjectJSON := JObject.ToString();
        exit(true);
    end;

    procedure GetObjectsFromJSONResponse(ResponseText: Text; ObjectIDFieldName: Text; ObjectID1: Text; ObjectID2: Text; var ObjectJSON1: Text; var ObjectJSON2: Text): Boolean
    var
        JSONManagement: Codeunit "JSON Management";
        JSONObject: DotNet JObject;
        JObject: DotNet JObject;
        ObjectJSON: Text;
        CurrentObjectID: Text;
        I: Integer;
        ObjectID1Found: Boolean;
        ObjectID2Found: Boolean;
        ObjectCollectionTxt: Text;
    begin
        JSONManagement.InitializeObject(ResponseText);
        JSONManagement.GetJSONObject(JSONObject);
        JSONManagement.GetStringPropertyValueFromJObjectByName(JSONObject, 'value', ObjectCollectionTxt);

        Clear(JSONManagement);
        JSONManagement.InitializeCollection(ObjectCollectionTxt);

        Assert.IsTrue(JSONManagement.GetCollectionCount() >= 2, 'At least 2 items should be returned');
        for I := 0 to JSONManagement.GetCollectionCount() - 1 do begin
            if not JSONManagement.GetJObjectFromCollectionByIndex(JObject, I) then
                exit(false);
            ObjectJSON := JObject.ToString();
            if GetObjectIDFromJSON(ObjectJSON, ObjectIDFieldName, CurrentObjectID) then begin
                if CurrentObjectID = ObjectID1 then begin
                    ObjectID1Found := true;
                    ObjectJSON1 := ObjectJSON;
                end;

                if CurrentObjectID = ObjectID2 then begin
                    ObjectID2Found := true;
                    ObjectJSON2 := ObjectJSON;
                end;
            end;

            if ObjectID1Found and ObjectID2Found then
                exit(true)
        end;

        exit(false);
    end;

    [TryFunction]
    procedure GetErrorFromJSONResponse(ResponseText: Text; var ErrorCode: Text; var ErrorMessage: Text)
    var
        JSONManagement: Codeunit "JSON Management";
        JObject: DotNet JObject;
    begin
        GetComplexPropertyFromJSON(ResponseText, 'error', JObject);
        JSONManagement.GetStringPropertyValueFromJObjectByName(JObject, 'code', ErrorCode);
        JSONManagement.GetStringPropertyValueFromJObjectByName(JObject, 'message', ErrorMessage);
    end;

    procedure GetObjectIDFromJSON(JSONTxt: Text; ObjectIDFieldName: Text; var ObjectIDValue: Text): Boolean
    var
        JSONManagement: Codeunit "JSON Management";
        JObject: DotNet JObject;
    begin
        JSONManagement.InitializeObject(JSONTxt);
        JSONManagement.GetJSONObject(JObject);
        exit(JSONManagement.GetStringPropertyValueFromJObjectByName(JObject, ObjectIDFieldName, ObjectIDValue));
    end;

    [Scope('OnPrem')]
    procedure GetCollectionCountFromJSON(JSON: Text): Integer
    var
        JsonMgt: Codeunit "JSON Management";
        JsonObject: DotNet JObject;
    begin
        JsonMgt.InitializeCollection(JSON);
        JsonMgt.GetJSONObject(JsonObject);
        exit(JsonMgt.GetCollectionCount());
    end;

    procedure GetObjectFromCollectionByIndex(JSON: Text; Index: Integer): Text
    var
        JSONManagement: Codeunit "JSON Management";
        JSONObject: DotNet JObject;
        RetrievedJSONObject: DotNet JObject;
    begin
        JSONManagement.InitializeCollection(JSON);
        JSONManagement.GetJSONObject(JSONObject);
        Assert.IsTrue(
          JSONManagement.GetJObjectFromCollectionByIndex(RetrievedJSONObject, Index),
          'Could not find object number: ' + Format(Index));

        JSONManagement.InitializeObjectFromJObject(RetrievedJSONObject);
        exit(JSONManagement.WriteObjectToString());
    end;

    procedure VerifyAddressProperties(JSON: Text; ExpectedLine1: Text; ExpectedLine2: Text; ExpectedCity: Text; ExpectedState: Text; ExpectedCountryCode: Text; ExpectedPostCode: Text)
    var
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        AddressObject: DotNet JObject;
    begin
        GetComplexPropertyFromJSON(JSON, 'address', AddressObject);
        AssertPropertyInJsonObject(AddressObject, 'street', GraphCollectionMgtContact.ConcatenateStreet(ExpectedLine1, ExpectedLine2));
        AssertPropertyInJsonObject(AddressObject, 'city', ExpectedCity);
        AssertPropertyInJsonObject(AddressObject, 'state', ExpectedState);
        AssertPropertyInJsonObject(AddressObject, 'countryLetterCode', ExpectedCountryCode);
        AssertPropertyInJsonObject(AddressObject, 'postalCode', ExpectedPostCode);
    end;

    procedure VerifyError(JSON: Text; ExpectedCode: Text; ExpectedMessage: Text)
    var
        ErrorObject: DotNet JObject;
    begin
        GetComplexPropertyFromJSON(JSON, 'error', ErrorObject);
        AssertPropertyInJsonObject(ErrorObject, 'code', ExpectedCode);
        AssertPropertyInJsonObject(ErrorObject, 'message', ExpectedMessage);
    end;

    procedure VerifyIDInJson(JSONTxt: Text)
    begin
        VerifyIDFieldInJson(JSONTxt, 'id');
    end;

    procedure VerifyIDFieldInJson(JSONTxt: Text; IDFieldName: Text)
    var
        JSONManagement: Codeunit "JSON Management";
        JObject: DotNet JObject;
        IdValue: Text;
        BlankGuid: Guid;
        IDGuid: Guid;
    begin
        JSONManagement.InitializeObject(JSONTxt);
        JSONManagement.GetJSONObject(JObject);
        Assert.IsTrue(JSONManagement.GetStringPropertyValueFromJObjectByName(JObject, IDFieldName, IdValue),
          'Could not find the ' + IDFieldName + ' property in' + JSONTxt);
        Assert.AreNotEqual('', IdValue, IDFieldName + ' should not be blank in ' + JSONTxt);
        Assert.IsTrue(Evaluate(IDGuid, IdValue), 'Id is not a guid');
        Assert.AreNotEqual(IDGuid, BlankGuid, 'Id most not be a blank guid in ' + JSONTxt);
    end;

    procedure VerifyIDFieldInJsonWithoutIntegrationRecord(JSONTxt: Text; IDFieldName: Text)
    var
        JSONManagement: Codeunit "JSON Management";
        JObject: DotNet JObject;
        IdValue: Text;
    begin
        JSONManagement.InitializeObject(JSONTxt);
        JSONManagement.GetJSONObject(JObject);
        Assert.IsTrue(JSONManagement.GetStringPropertyValueFromJObjectByName(JObject, IDFieldName, IdValue),
          'Could not find the ' + IDFieldName + ' property in' + JSONTxt);
        Assert.AreNotEqual('', IdValue, IDFieldName + ' should not be blank in ' + JSONTxt);
    end;

    procedure VerifyUoMInJson(JSONTxt: Text; UnitofMeasureCode: Code[10]; ItemIdentifierTxt: Text)
    var
        Item: Record Item;
        JSONManagement: Codeunit "JSON Management";
        JObject: DotNet JObject;
        ItemIdValue: Text;
        JSONUoMValue: Text;
        UnitCodeValue: Text;
    begin
        JSONManagement.InitializeObject(JSONTxt);
        JSONManagement.GetJSONObject(JObject);
        Assert.IsTrue(JSONManagement.GetStringPropertyValueFromJObjectByName(JObject, ItemIdentifierTxt, ItemIdValue),
          'Could not find the ItemId property in' + JSONTxt);

        Assert.AreNotEqual('', ItemIdValue, 'ItemId should not be blank in ' + JSONTxt);

        Assert.IsTrue(JSONManagement.GetStringPropertyValueFromJObjectByName(JObject, 'baseUnitOfMeasure', JSONUoMValue),
          'Could not find the BaseUnitOfMeasure property in' + JSONTxt);
        Assert.AreNotEqual('', JSONUoMValue, 'BaseUnitOfMeasure should not be blank in ' + JSONTxt);

        JSONManagement.InitializeObject(JSONUoMValue);
        JSONManagement.GetJSONObject(JObject);
        Assert.IsTrue(
          JSONManagement.GetStringPropertyValueFromJObjectByName(JObject, GraphCollectionMgtItem.UOMComplexTypeUnitCode(), UnitCodeValue),
          'Could not find the Unit Code property in' + JSONTxt);

        Assert.AreEqual(UnitofMeasureCode, UnitCodeValue, 'Incorrect UoM in JSON');

        Item.Reset();
        Item.Get(ItemIdValue);
        Assert.AreEqual(UnitofMeasureCode, Item."Base Unit of Measure", 'Incorrect UoM in table Item');
    end;

    procedure VerifyGUIDFieldInJson(JSONTxt: Text; GUIDFieldName: Text; ExpectedValue: Guid)
    var
        JSONManagement: Codeunit "JSON Management";
        JObject: DotNet JObject;
        StringValue: Text;
        ActualValue: Guid;
    begin
        JSONManagement.InitializeObject(JSONTxt);
        JSONManagement.GetJSONObject(JObject);
        Assert.IsTrue(JSONManagement.GetStringPropertyValueFromJObjectByName(JObject, GUIDFieldName, StringValue),
          'Could not find the ' + GUIDFieldName + ' property in' + JSONTxt);
        Assert.IsTrue(Evaluate(ActualValue, StringValue), 'Property value ' + StringValue + ' is not guid');
        Assert.AreEqual(ActualValue, ExpectedValue,
          'Incorrect property value for ' + GUIDFieldName);
    end;

    procedure VerifyPropertyInJSON(JSONTxt: Text; FieldName: Text; FieldValue: Text)
    var
        JSONManagement: Codeunit "JSON Management";
        JObject: DotNet JObject;
    begin
        JSONManagement.InitializeObject(JSONTxt);
        JSONManagement.GetJSONObject(JObject);
        AssertPropertyInJsonObject(JObject, FieldName, FieldValue);
    end;

    procedure StripBrackets(StringWithBrackets: Text): Text
    begin
        if StrPos(StringWithBrackets, '{') = 1 then
            exit(CopyStr(Format(StringWithBrackets), 2, 36));
        exit(StringWithBrackets);
    end;

    local procedure GetTextResponseAndCheckForErrors(var HttpRequestMessage: HttpRequestMessage; var ResponseText: Text; ExpectedResponseCode: Integer)
    var
        ResponseHeaders: Dictionary of [Text, Text];
    begin
        GetTextResponseAndCheckForErrorsExtended(HttpRequestMessage, ResponseText, ResponseHeaders, ExpectedResponseCode);
    end;

    local procedure GetTextResponseAndCheckForErrorsExtended(var HttpRequestMessage: HttpRequestMessage; var ResponseText: Text; var ResponseHeaders: Dictionary of [Text, Text]; ExpectedResponseCode: Integer)
    var
        ResponseError: Text;
        ResponseStatusName: Text;
        Method: Text;
        ResponseStatusCode: Integer;
        Successful: Boolean;
    begin
        Method := HttpRequestMessage.Method();
        Successful := ExecuteWebRequestAndReadTextResponse(HttpRequestMessage, ResponseText, ResponseError, ResponseStatusCode, ResponseStatusName, ResponseHeaders);
        CheckResponseForErrors(Method, Successful, ResponseError, ResponseStatusCode, ResponseStatusName, ExpectedResponseCode);
    end;

    local procedure GetResponseAndCheckForErrors(var HttpRequestMessage: HttpRequestMessage; var TempBlob: Codeunit "Temp Blob"; ExpectedResponseCode: Integer)
    var
        ResponseHeaders: Dictionary of [Text, Text];
        ResponseError: Text;
        ResponseStatusName: Text;
        Method: Text;
        ResponseStatusCode: Integer;
        Successful: Boolean;
    begin
        Method := HttpRequestMessage.Method();
        Successful := ExecuteWebRequestAndReadResponse(HttpRequestMessage, TempBlob, ResponseError, ResponseStatusCode, ResponseStatusName, ResponseHeaders);
        CheckResponseForErrors(Method, Successful, ResponseError, ResponseStatusCode, ResponseStatusName, ExpectedResponseCode);
    end;

    local procedure CheckResponseForErrors(Method: Text; Successful: Boolean; ResponseError: Text; ActualResponseCode: Integer; ResponseStatusName: Text; ExpectedResponseCode: Integer)
    begin
        if Successful then begin
            if ExpectedResponseCode <> ActualResponseCode then
                Assert.Fail(StrSubstNo(UnexpectedResponseCodeErr, ActualResponseCode, ResponseStatusName, ExpectedResponseCode));
            exit;
        end;

        if ExpectedResponseCode <> ActualResponseCode then
            Assert.Fail(StrSubstNo(FailedRequestWithUnexpectedResponseCodeErr,
                Method, ActualResponseCode, ResponseStatusName, ExpectedResponseCode, ResponseError))
        else
            Assert.Fail(StrSubstNo(FailedRequestErr, Method, ActualResponseCode, ResponseStatusName, ResponseError));
    end;

    [Normal]
    procedure CreateTargetURLWithTwoSubpages(ID: Text; SubPageID: Text; PageNumber: Integer; ServiceNameTxt: Text; ServiceSubPageTxt: Text; ServiceSubSubPageTxt: Text): Text
    var
        TargetURL: Text;
    begin
        TargetURL := CreateTargetURL(ID, PageNumber, ServiceNameTxt);
        if ServiceSubPageTxt <> '' then
            TargetURL := AppendPathToTargetURL(TargetURL, '/' + ServiceSubPageTxt);
        if SubPageID <> '' then
            TargetURL := AppendPathToTargetURL(
                TargetURL, '(' + StripBrackets(SubPageID) + ')');
        if ServiceSubSubPageTxt <> '' then
            TargetURL := AppendPathToTargetURL(TargetURL, '/' + ServiceSubSubPageTxt);
        exit(TargetURL);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitializeWebRequestWithURL(var HttpRequestMessage: HttpRequestMessage)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnExecuteWebRequestAndReadResponseOnBeforeGetResponse(var HttpRequestMessage: HttpRequestMessage)
    begin
    end;
}
