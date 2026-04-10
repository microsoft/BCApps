codeunit 130618 "Library - Graph Mgt"
{

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        IncorrectValueErr: Label 'Incorrect value found in JSON for %1 property.', Comment = '%1 - Name of property';
        GraphCollectionMgtItem: Codeunit "Graph Collection Mgt - Item";
        UnexpectedResponseCodeErr: Label 'Response code %1 (%2) differs from the expected %3.', Comment = '%1 - Actual response code number, %2 - Actual response code, %3 - Expected response code number';
        FailedRequestErr: Label '%1 request failed. Response code is %2 (%3). %4', Comment = '%1 - request method, %2 - response code number, %3 - response code, %4 - error message';
        FailedRequestWithUnexpectedResponseCodeErr: Label '%1 request failed. Response code is %2 (%3), expected code is %4. %5', Comment = '%1 - request method, %2 - response code number, %3 - response code, %4 - expected response code, %5 - error message';

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
        HttpWebRequestMgt: Codeunit "Http Web Request Mgt.";
    begin
        InitializeWebRequestWithURL(HttpWebRequestMgt, TargetURL);
        HttpWebRequestMgt.SetMethod('GET');
        HttpWebRequestMgt.SetContentType('application/json;odata.metadata=minimal');
        HttpWebRequestMgt.SetReturnType('application/json');

        GetTextResponseAndCheckForErrors(HttpWebRequestMgt, ResponseText, ExpectedResponseCode);
    end;

    procedure GetBinaryFromWebServiceAndCheckResponseCode(var TempBlob: Codeunit "Temp Blob"; TargetURL: Text; ReturnType: Text; ExpectedResponseCode: Integer)
    var
        HttpWebRequestMgt: Codeunit "Http Web Request Mgt.";
    begin
        InitializeWebRequestWithURL(HttpWebRequestMgt, TargetURL);
        HttpWebRequestMgt.SetMethod('GET');
        HttpWebRequestMgt.SetContentType('application/json;odata.metadata=minimal');
        HttpWebRequestMgt.SetReturnType(ReturnType);

        GetResponseAndCheckForErrors(HttpWebRequestMgt, TempBlob, ExpectedResponseCode);
    end;

    procedure PostToWebServiceAndCheckResponseCode(TargetURL: Text; JSONBody: Text; var ResponseText: Text; ExpectedResponseCode: Integer)
    var
        HttpWebRequestMgt: Codeunit "Http Web Request Mgt.";
    begin
        InitializeWebRequestWithURL(HttpWebRequestMgt, TargetURL);
        HttpWebRequestMgt.SetReturnType('application/json');
        HttpWebRequestMgt.SetContentType('application/json;odata.metadata=minimal');
        HttpWebRequestMgt.SetMethod('POST');
        HttpWebRequestMgt.AddBodyAsText(JSONBody);

        GetTextResponseAndCheckForErrors(HttpWebRequestMgt, ResponseText, ExpectedResponseCode);
    end;

    [Scope('OnPrem')]
    procedure PostToWebServiceAndCheckResponseCodeExtended(TargetURL: Text; JSONBody: Text; var ResponseText: Text; var ResponseHeaders: DotNet NameValueCollection; ExpectedResponseCode: Integer)
    var
        HttpWebRequestMgt: Codeunit "Http Web Request Mgt.";
    begin
        InitializeWebRequestWithURL(HttpWebRequestMgt, TargetURL);
        HttpWebRequestMgt.SetReturnType('application/json');
        HttpWebRequestMgt.SetContentType('application/json;odata.metadata=minimal');
        HttpWebRequestMgt.SetMethod('POST');
        HttpWebRequestMgt.AddBodyAsText(JSONBody);

        GetTextResponseAndCheckForErrorsExtended(HttpWebRequestMgt, ResponseText, ResponseHeaders, ExpectedResponseCode);
    end;

    local procedure UpdateToWebServiceAndCheckResponseCode(TargetURL: Text; JSONBody: Text; Method: Text; var ResponseText: Text; ExpectedResponseCode: Integer)
    var
        HttpWebRequestMgt: Codeunit "Http Web Request Mgt.";
        ETag: Text;
    begin
        ETag := GetEtag(TargetURL);

        InitializeWebRequestWithURL(HttpWebRequestMgt, TargetURL);
        HttpWebRequestMgt.SetContentType('application/json;odata.metadata=minimal');
        HttpWebRequestMgt.SetReturnType('application/json');
        HttpWebRequestMgt.SetMethod(Method);
        HttpWebRequestMgt.AddHeader('If-Match', ETag);
        HttpWebRequestMgt.AddBodyAsText(JSONBody);

        GetTextResponseAndCheckForErrors(HttpWebRequestMgt, ResponseText, ExpectedResponseCode);
    end;

    procedure BinaryUpdateToWebServiceAndCheckResponseCode(TargetURL: Text; var TempBlob: Codeunit "Temp Blob"; Method: Text; var ResponseText: Text; ExpectedResponseCode: Integer)
    var
        HttpWebRequestMgt: Codeunit "Http Web Request Mgt.";
        ETag: Text;
    begin
        ETag := '*';

        InitializeWebRequestWithURL(HttpWebRequestMgt, TargetURL);
        HttpWebRequestMgt.SetContentType('application/octet-stream');
        HttpWebRequestMgt.SetReturnType('application/json');
        HttpWebRequestMgt.AddHeader('If-Match', ETag);
        HttpWebRequestMgt.SetMethod(Method);
        HttpWebRequestMgt.AddBodyBlob(TempBlob);

        GetTextResponseAndCheckForErrors(HttpWebRequestMgt, ResponseText, ExpectedResponseCode);
    end;

    procedure InitializeWebRequestWithURL(var HttpWebRequestMgt: Codeunit "Http Web Request Mgt."; TargetURL: Text)
    begin
        HttpWebRequestMgt.Initialize(TargetURL);
        OnAfterInitializeWebRequestWithURL(HttpWebRequestMgt);
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

    local procedure ExecuteWebRequestAndReadTextResponse(var HttpWebRequestMgt: Codeunit "Http Web Request Mgt."; var ResponseText: Text; var ResponseError: Text; var HttpStatusCode: DotNet HttpStatusCode; var ResponseHeaders: DotNet NameValueCollection): Boolean
    var
        TempBlob: Codeunit "Temp Blob";
        ResponseInStream: InStream;
        TextLine: Text;
    begin
        if not ExecuteWebRequestAndReadResponse(HttpWebRequestMgt, TempBlob, ResponseError, HttpStatusCode, ResponseHeaders) then
            exit(false);

        TempBlob.CreateInStream(ResponseInStream);
        while ResponseInStream.ReadText(TextLine) > 0 do
            ResponseText += TextLine;

        exit(true);
    end;

    local procedure ExecuteWebRequestAndReadResponse(var HttpWebRequestMgt: Codeunit "Http Web Request Mgt."; var TempBlob: Codeunit "Temp Blob"; var ResponseError: Text; var HttpStatusCode: DotNet HttpStatusCode; var ResponseHeaders: DotNet NameValueCollection): Boolean
    var
        WebRequestHelper: Codeunit "Web Request Helper";
        WebException: DotNet WebException;
        WebExceptionResponse: DotNet HttpWebResponse;
        ResponseInStream: InStream;
        WebExceptionResponseText: Text;
        TextLine: Text;
        ServiceUrl: Text;
        LastError: Text;
        ErrorCode: Text;
        ErrorMessage: Text;
    begin
        Clear(TempBlob);
        TempBlob.CreateInStream(ResponseInStream);

        ClearLastError();
        OnExecuteWebRequestAndReadResponseOnBeforeGetResponse(HttpWebRequestMgt);
        if HttpWebRequestMgt.GetResponse(ResponseInStream, HttpStatusCode, ResponseHeaders) then
            exit(true);

        LastError := GetLastErrorText;
        ResponseError := LastError;

        WebRequestHelper.GetWebResponseError(WebException, ServiceUrl);
        WebExceptionResponse := WebException.Response;
        if SYSTEM.IsNull(WebExceptionResponse) then
            exit(false);

        HttpStatusCode := WebExceptionResponse.StatusCode;
        ResponseHeaders := WebExceptionResponse.Headers;
        WebExceptionResponse.GetResponseStream().CopyTo(ResponseInStream);
        while ResponseInStream.ReadText(TextLine) > 0 do
            WebExceptionResponseText += TextLine;

        if not GetErrorFromJSONResponse(WebExceptionResponseText, ErrorCode, ErrorMessage) then
            exit(false);

        ResponseError := '';
        if ErrorCode <> '' then
            ResponseError += STRREPLACE(StrSubstNo('Error code: %1. ', ErrorCode), '..', '.');
        if ErrorMessage <> '' then
            ResponseError += STRREPLACE(StrSubstNo('Error message: %1. ', ErrorMessage), '..', '.');
        ResponseError += LastError;
        exit(false);
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

    local procedure GetTextResponseAndCheckForErrors(var HttpWebRequestMgt: Codeunit "Http Web Request Mgt."; var ResponseText: Text; ExpectedResponseCode: Integer)
    var
        ResponseHeaders: DotNet NameValueCollection;
    begin
        GetTextResponseAndCheckForErrorsExtended(HttpWebRequestMgt, ResponseText, ResponseHeaders, ExpectedResponseCode);
    end;

    local procedure GetTextResponseAndCheckForErrorsExtended(var HttpWebRequestMgt: Codeunit "Http Web Request Mgt."; var ResponseText: Text; var ResponseHeaders: DotNet NameValueCollection; ExpectedResponseCode: Integer)
    var
        HttpStatusCode: DotNet HttpStatusCode;
        ResponseError: Text;
        Method: Text;
        Successful: Boolean;
    begin
        Method := HttpWebRequestMgt.GetMethod();
        Successful := ExecuteWebRequestAndReadTextResponse(HttpWebRequestMgt, ResponseText, ResponseError, HttpStatusCode, ResponseHeaders);
        CheckResponseForErrors(Method, Successful, ResponseError, HttpStatusCode, ExpectedResponseCode);
    end;

    local procedure GetResponseAndCheckForErrors(var HttpWebRequestMgt: Codeunit "Http Web Request Mgt."; var TempBlob: Codeunit "Temp Blob"; ExpectedResponseCode: Integer)
    var
        ResponseHeaders: DotNet NameValueCollection;
    begin
        GetResponseAndCheckForErrorsExtended(HttpWebRequestMgt, TempBlob, ResponseHeaders, ExpectedResponseCode);
    end;

    local procedure GetResponseAndCheckForErrorsExtended(var HttpWebRequestMgt: Codeunit "Http Web Request Mgt."; var TempBlob: Codeunit "Temp Blob"; var ResponseHeaders: DotNet NameValueCollection; ExpectedResponseCode: Integer)
    var
        HttpStatusCode: DotNet HttpStatusCode;
        ResponseError: Text;
        Method: Text;
        Successful: Boolean;
    begin
        Method := HttpWebRequestMgt.GetMethod();
        Successful := ExecuteWebRequestAndReadResponse(HttpWebRequestMgt, TempBlob, ResponseError, HttpStatusCode, ResponseHeaders);
        CheckResponseForErrors(Method, Successful, ResponseError, HttpStatusCode, ExpectedResponseCode);
    end;

    local procedure CheckResponseForErrors(Method: Text; Successful: Boolean; ResponseError: Text; var HttpStatusCode: DotNet HttpStatusCode; ExpectedResponseCode: Integer)
    var
        ActualResponseCode: Integer;
    begin
        if not IsNull(HttpStatusCode) then
            ActualResponseCode := HttpStatusCode;

        if Successful then begin
            if ExpectedResponseCode <> ActualResponseCode then
                Assert.Fail(StrSubstNo(UnexpectedResponseCodeErr, ActualResponseCode, HttpStatusCode, ExpectedResponseCode));
            exit;
        end;

        if ExpectedResponseCode <> ActualResponseCode then
            Assert.Fail(StrSubstNo(FailedRequestWithUnexpectedResponseCodeErr,
                Method, ActualResponseCode, HttpStatusCode, ExpectedResponseCode, ResponseError))
        else
            Assert.Fail(StrSubstNo(FailedRequestErr, Method, ActualResponseCode, HttpStatusCode, ResponseError));
    end;

    [Normal]
    procedure CreateTargetURLWithTwoSubpages(ID: Text; SubPageID: Text; PageNumber: Integer; ServiceNameTxt: Text; ServiceSubPageTxt: Text; ServiceSubSubPageTxt: Text): Text
    var
        TargetURL: Text;
    begin
        TargetURL := GetODataTargetURL(ObjectType::Page, PageNumber);
        TargetURL := AppendSubpageToTargetURL(ID, TargetURL, ServiceNameTxt, ServiceSubPageTxt);
        exit(AppendSubpageToTargetURL(SubPageID, TargetURL, ServiceSubPageTxt, ServiceSubSubPageTxt));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitializeWebRequestWithURL(var HttpWebRequestMgt: Codeunit "Http Web Request Mgt.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnExecuteWebRequestAndReadResponseOnBeforeGetResponse(var HttpWebRequestMgt: Codeunit "Http Web Request Mgt.")
    begin
    end;
}

