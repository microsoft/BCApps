namespace Microsoft.CRM.Outlook;
using Microsoft.CRM.Contact;

codeunit 7106 "O365 Bidirectional Sync"
{
    var
        TempSyncQueue: Record "Contact Sync Queue" temporary;
        LastSyncCreatedCount: Integer;
        SyncStartDateTime: DateTime;
        NextEntryNo: Integer;
        NoContactsFoundMsg: Label 'No contacts found in the selected folder.';
        ContentTypeLbl: Label 'application/json', Locked = true;
        ResponseLbl: Label 'Folder ID not found in the response.';
        RetrievedContactsMsg: Label 'Found %1 contacts', Comment = '%1 = count of contacts';
        InvalidJsonMsg: Label 'Invalid JSON response received from Microsoft Graph.';
        NoContactsDataMsg: Label 'No contacts data found in the response.';
        NoContactFoldersMsg: Label 'No contact folders found in the response.';
        AccessTokenEmptyMsg: Label 'Access token cannot be empty';
        GraphApiUrlTxt: Label 'https://graph.microsoft.com/v1.0/me/contactFolders/', Locked = true;
        GraphEndpointTxt: Label '/contacts?$top=999', Locked = true;
        NetworkErrorMsg: Label 'Unable to connect to Microsoft Graph API. Please check your network connection.';
        GetContactsStartTxt: Label 'Starting GetContacts procedure for folder %1 with filter: %2', Comment = '%1 = folder id, %2 = filter text', Locked = true;
        FetchingContactsFromGraphTxt: Label 'Fetching contacts from Graph API endpoint: %1', Comment = '%1 = endpoint URI', Locked = true;
        ContactsRetrievedCountTxt: Label 'Retrieved %1 contacts from Microsoft Graph API response', Comment = '%1 = count of contacts', Locked = true;
        ComparingQueueingContactsTxt: Label 'Comparing and queueing contacts for synchronization', Locked = true;
        TotalContactsQueuedTxt: Label 'Total contacts queued for synchronization: %1', Comment = '%1 = count of queued contacts', Locked = true;
        GetContactsCompleteTxt: Label 'GetContacts procedure completed successfully', Locked = true;
        PaginationNextLinkTxt: Label 'Found pagination link, fetching next page from: %1', Comment = '%1 = next page URI', Locked = true;
        NoPaginationLinkTxt: Label 'No more pages to fetch, pagination complete', Locked = true;
        // JSON Property Names
        ContactIdPropertyTxt: Label 'id', Locked = true, Comment = 'Microsoft Graph Contact ID property';
        DisplayNamePropertyTxt: Label 'displayName', Locked = true, Comment = 'Microsoft Graph Display Name property';
        GivenNamePropertyTxt: Label 'givenName', Locked = true, Comment = 'Microsoft Graph Given Name property';
        SurnamePropertyTxt: Label 'surname', Locked = true, Comment = 'Microsoft Graph Surname property';
        JobTitlePropertyTxt: Label 'jobTitle', Locked = true, Comment = 'Microsoft Graph Job Title property';
        CompanyNamePropertyTxt: Label 'companyName', Locked = true, Comment = 'Microsoft Graph Company Name property';
        MobilePhonePropertyTxt: Label 'mobilePhone', Locked = true, Comment = 'Microsoft Graph Mobile Phone property';
        MiddleNamePropertyTxt: Label 'middleName', Locked = true, Comment = 'Microsoft Graph Middle Name property';
        InitialsPropertyTxt: Label 'initials', Locked = true, Comment = 'Microsoft Graph Initials property';
        BusinessHomePagePropertyTxt: Label 'businessHomePage', Locked = true, Comment = 'Microsoft Graph Business Home Page property';
        PrimaryEmailAddressPropertyTxt: Label 'primaryEmailAddress', Locked = true, Comment = 'Microsoft Graph Primary Email Address property';
        EmailAddressesPropertyTxt: Label 'emailAddresses', Locked = true, Comment = 'Microsoft Graph Email Addresses array property';
        BusinessPhonesPropertyTxt: Label 'businessPhones', Locked = true, Comment = 'Microsoft Graph Business Phones array property';
        HomePhnesPropertyTxt: Label 'homePhones', Locked = true, Comment = 'Microsoft Graph Home Phones array property';
        CreatedDateTimePropertyTxt: Label 'createdDateTime', Locked = true, Comment = 'Microsoft Graph Created DateTime property';
        LastModifiedDateTimePropertyTxt: Label 'lastModifiedDateTime', Locked = true, Comment = 'Microsoft Graph Last Modified DateTime property';
        BusinessAddressPropertyTxt: Label 'businessAddress', Locked = true, Comment = 'Microsoft Graph Business Address property';
        HomeAddressPropertyTxt: Label 'homeAddress', Locked = true, Comment = 'Microsoft Graph Home Address property';
        StreetPropertyTxt: Label 'street', Locked = true, Comment = 'Microsoft Graph Street property (for address)';
        CityPropertyTxt: Label 'city', Locked = true, Comment = 'Microsoft Graph City property (for address)';
        PostalCodePropertyTxt: Label 'postalCode', Locked = true, Comment = 'Microsoft Graph Postal Code property (for address)';
        CountryOrRegionPropertyTxt: Label 'countryOrRegion', Locked = true, Comment = 'Microsoft Graph Country Or Region property (for address)';
        AddressPropertyTxt: Label 'address', Locked = true, Comment = 'Microsoft Graph Address property (for email)';
        CategoriesPropertyTxt: Label 'categories', Locked = true, Comment = 'Microsoft Graph Categories array property';
        ValuePropertyTxt: Label 'value', Locked = true, Comment = 'Microsoft Graph value property (for arrays)';
        ErrorPropertyTxt: Label 'error', Locked = true, Comment = 'Microsoft Graph error object property';
        ErrorCodePropertyTxt: Label 'code', Locked = true, Comment = 'Microsoft Graph error code property';
        ErrorMessagePropertyTxt: Label 'message', Locked = true, Comment = 'Microsoft Graph error message property';
        ODataNextLinkPropertyTxt: Label '@odata.nextLink', Locked = true, Comment = 'Microsoft Graph pagination next link property';
        ParentFolderIdPropertyTxt: Label 'parentFolderId', Locked = true, Comment = 'Microsoft Graph Parent Folder ID property';
        // HTTP Headers
        AuthorizationHeaderTxt: Label 'Authorization', Locked = true, Comment = 'HTTP Authorization header';
        BearerTokenFormatTxt: Label 'Bearer %1', Locked = true, Comment = '%1 = access token';
        AcceptHeaderTxt: Label 'Accept', Locked = true, Comment = 'HTTP Accept header';
        ApplicationJsonHeaderTxt: Label 'application/json', Locked = true, Comment = 'HTTP Content-Type value for JSON';
        RequestBodyTxt: Label '{ "displayName": "%1" }', Locked = true, Comment = '%1 = FolderName';
        // Telemetry/Logging Messages
        CategoryLbl: Label 'Contact Sync', Locked = true;
        HttpGetRequestFailedTxt: Label 'HTTP Get request failed', Comment = 'Error message for HTTP GET failure', Locked = true;
        ReceivedHttpResponseTxt: Label 'Received HTTP response with status code: %1', Locked = true, Comment = '%1 = HTTP status code';
        StartingSyncingFoldersTxt: Label 'Starting Syncing Contact Folders', Comment = 'Telemetry message when starting folder sync', Locked = true;
        ReceivedFolderResponseTxt: Label 'Received response from Graph API for Contact Folders %1', Locked = true, Comment = '%1 = HTTP status code';
        FolderErrorResponseTxt: Label 'Error response from Graph API for Contact Folders %1', Locked = true, Comment = '%1 = HTTP status code';
        // HTTP Status Code Error Messages
        Http401UnauthorizedErr: Label 'HTTP 401 - Unauthorized: %1', Locked = true, Comment = '%1 = error message';
        Http403ForbiddenErr: Label 'HTTP 403 - Forbidden: %1', Locked = true, Comment = '%1 = error message';
        Http429TooManyRequestsErr: Label 'HTTP 429 - Too Many Requests: %1', Locked = true, Comment = '%1 = error message';
        Http500InternalServerErr: Label 'HTTP 500 - Internal Server Error: %1', Locked = true, Comment = '%1 = error message';
        Http502BadGatewayErr: Label 'HTTP 502 - Bad Gateway: %1', Locked = true, Comment = '%1 = error message';
        Http503ServiceUnavailableErr: Label 'HTTP 503 - Service Unavailable: %1', Locked = true, Comment = '%1 = error message';
        HttpGenericErr: Label 'HTTP %1 Error: %2', Locked = true, Comment = '%1 = HTTP status code, %2 = error message';
        HttpUnexpectedResponseErr: Label 'HTTP %1 - Unexpected error response format', Locked = true, Comment = '%1 = HTTP status code';
        HttpParseErrorErr: Label 'HTTP %1 - Unable to parse error response', Locked = true, Comment = '%1 = HTTP status code';
        HttpStatusErrorLogTxt: Label 'HTTP Status %1: %2 - %3', Locked = true, Comment = '%1 = HTTP status code, %2 = error code, %3 = error message';
        // Telemetry-only Messages (Locked for consistent logging)
        AccessTokenEmptyTeleTxt: Label 'Access token is empty', Locked = true;
        InvalidJsonTeleTxt: Label 'Invalid JSON response received from Microsoft Graph', Locked = true;
        NetworkErrorTeleTxt: Label 'Network error occurred: %1', Locked = true, Comment = '%1 = error description';


    procedure GetContacts(AccessToken: SecretText; var OutSyncQueue: Record "Contact Sync Queue" temporary; ContactFilterText: Text; FolderId: Text)
    var
        O365Records: Record "O365 Contact";
        HttpClient: HttpClient;
        HttpResponse: HttpResponseMessage;
        JsonResponse: Text;
        Uri: Text;
        NextLink: Text;
        JsonObj: JsonObject;
        JsonValue: JsonToken;
    begin
        OutSyncQueue.DeleteAll();

        SyncStartDateTime := CurrentDateTime;
        LastSyncCreatedCount := 0;

        Session.LogMessage('0000QT8', StrSubstNo(GetContactsStartTxt, FolderId, ContactFilterText), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', getTracecat());

        if AccessToken.IsEmpty() then begin
            Session.LogMessage('0000QU4', AccessTokenEmptyTeleTxt, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', getTracecat());
            Error(AccessTokenEmptyMsg);
        end;

        Uri := GraphApiUrlTxt + FolderId + GraphEndpointTxt;

        Session.LogMessage('0000QT9', StrSubstNo(FetchingContactsFromGraphTxt, Uri), Verbosity::Verbose, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', getTracecat());

        SetupHttpClientHeaders(HttpClient, AccessToken);

        repeat
            if not HttpClient.Get(Uri, HttpResponse) then begin
                Session.LogMessage('0000QTA', StrSubstNo(NetworkErrorTeleTxt, HttpGetRequestFailedTxt), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', getTracecat());
                Error(NetworkErrorMsg);
            end;

            HttpResponse.Content.ReadAs(JsonResponse);

            Session.LogMessage('0000QTB', StrSubstNo(ReceivedHttpResponseTxt, HttpResponse.HttpStatusCode()), Verbosity::Verbose, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', getTracecat());

            if not HttpResponse.IsSuccessStatusCode() then begin
                Session.LogMessage('0000QTC', StrSubstNo(ReceivedHttpResponseTxt, HttpResponse.HttpStatusCode()), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', getTracecat());
                HandleErrorResponse(JsonResponse, HttpResponse.HttpStatusCode());
            end;

            // Parse JSON to find contacts
            Clear(O365Records);
            ParseContactsResponse(JsonResponse, O365Records);
            Session.LogMessage('0000QTD', StrSubstNo(ContactsRetrievedCountTxt, O365Records.Count()), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', getTracecat());

            // Compare and queue contacts
            Session.LogMessage('0000QTE', ComparingQueueingContactsTxt, Verbosity::Verbose, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', getTracecat());
            CompareAndQueueContacts(O365Records, ContactFilterText);
            Session.LogMessage('0000QTF', StrSubstNo(TotalContactsQueuedTxt, TempSyncQueue.Count()), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', getTracecat());

            // Copy queued items to out parameter
            if TempSyncQueue.FindSet() then
                repeat
                    OutSyncQueue := TempSyncQueue;
                    OutSyncQueue.Insert(false);
                until TempSyncQueue.Next() = 0;

            // Read nextLink for pagination
            Clear(JsonObj);
            if JsonObj.ReadFrom(JsonResponse) then
                if JsonObj.Contains(ODataNextLinkPropertyTxt) then begin
                    JsonObj.Get(ODataNextLinkPropertyTxt, JsonValue);
                    NextLink := JsonValue.AsValue().AsText();
                    Session.LogMessage('0000QTG', StrSubstNo(PaginationNextLinkTxt, NextLink), Verbosity::Verbose, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', getTracecat());
                end else begin
                    NextLink := '';
                    Session.LogMessage('0000QTH', NoPaginationLinkTxt, Verbosity::Verbose, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', getTracecat());
                end;

            Uri := NextLink;

        until Uri = '';

        Session.LogMessage('0000QTI', GetContactsCompleteTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', getTracecat());

        if OutSyncQueue.IsEmpty() then
            Message(NoContactsFoundMsg)
        else
            Message(RetrievedContactsMsg, OutSyncQueue.Count());
    end;



    local procedure ParseContactsResponse(JsonResponse: Text; var O365Records: Record "O365 Contact")
    var
        JsonToken: JsonToken;
        JsonObject: JsonObject;
        JsonArray: JsonArray;
        ContactToken: JsonToken;
        ContactObject: JsonObject;
        i: Integer;
    begin
        O365Records.Reset();
        O365Records.DeleteAll();

        if not JsonObject.ReadFrom(JsonResponse) then
            Error(InvalidJsonMsg);

        if not JsonObject.Get(ValuePropertyTxt, JsonToken) then
            Error(NoContactsDataMsg);

        JsonArray := JsonToken.AsArray();

        for i := 0 to JsonArray.Count() - 1 do begin
            JsonArray.Get(i, ContactToken);
            ContactObject := ContactToken.AsObject();

            O365Records.Init();
            // Parse email addresses
            O365Records."Email Address" := CopyStr(GetPrimaryEmailAddress(ContactObject), 1, MaxStrLen(O365Records."Email Address"));
            if O365Records."Email Address" = '' then
                continue;
            O365Records."Email 2" := CopyStr(GetSecondaryEmailAddress(ContactObject), 1, MaxStrLen(O365Records."Email 2"));
            O365Records."Display Name" := CopyStr(GetJsonValue(ContactObject, DisplayNamePropertyTxt), 1, MaxStrLen(O365Records."Display Name"));
            O365Records."Contact ID" := CopyStr(GetJsonValue(ContactObject, ContactIdPropertyTxt), 1, MaxStrLen(O365Records."Contact ID"));
            O365Records."Given Name" := CopyStr(GetJsonValue(ContactObject, GivenNamePropertyTxt), 1, MaxStrLen(O365Records."Given Name"));
            O365Records."Surname" := CopyStr(GetJsonValue(ContactObject, SurnamePropertyTxt), 1, MaxStrLen(O365Records."Surname"));
            O365Records."Job Title" := CopyStr(GetJsonValue(ContactObject, JobTitlePropertyTxt), 1, MaxStrLen(O365Records."Job Title"));
            if O365Records."Display Name" = '' then
                O365Records."Display Name" := CopyStr(O365Records."Given Name" + ' ' + O365Records."Surname", 1, MaxStrLen(O365Records."Display Name"));
            O365Records."Company Name" := CopyStr(GetJsonValue(ContactObject, CompanyNamePropertyTxt), 1, MaxStrLen(O365Records."Company Name"));
            O365Records."Mobile Phone" := CopyStr(GetJsonValue(ContactObject, MobilePhonePropertyTxt), 1, MaxStrLen(O365Records."Mobile Phone"));

            // Parse additional contact fields
            O365Records."Middle Name" := CopyStr(GetJsonValue(ContactObject, MiddleNamePropertyTxt), 1, MaxStrLen(O365Records."Middle Name"));
            O365Records."Initials" := CopyStr(GetJsonValue(ContactObject, InitialsPropertyTxt), 1, MaxStrLen(O365Records."Initials"));
            O365Records."Home Page" := CopyStr(GetJsonValue(ContactObject, BusinessHomePagePropertyTxt), 1, MaxStrLen(O365Records."Home Page"));


            // Parse phone numbers
            O365Records."Business Phone" := CopyStr(GetBusinessPhone(ContactObject), 1, MaxStrLen(O365Records."Business Phone"));
            O365Records."Home Phone" := CopyStr(GetHomePhone(ContactObject), 1, MaxStrLen(O365Records."Home Phone"));

            // Parse dates
            O365Records."Created DateTime" := GetDateTimeValue(ContactObject, CreatedDateTimePropertyTxt);
            O365Records."Last Modified DateTime" := GetDateTimeValue(ContactObject, LastModifiedDateTimePropertyTxt);

            // Parse address information
            ParseAddressFields(ContactObject, O365Records);

            // Parse categories
            O365Records."Categories" := CopyStr(GetCategoriesAsText(ContactObject), 1, MaxStrLen(O365Records."Categories"));

            O365Records.Insert();
        end;
    end;

    local procedure ParseAddressFields(JsonObject: JsonObject; var O365Records: Record "O365 Contact")
    var
        BusinessAddressObject: JsonObject;
        JsonToken: JsonToken;
    begin
        // Try to get business address first, then home address
        if JsonObject.Get(BusinessAddressPropertyTxt, JsonToken) and JsonToken.IsObject() then
            BusinessAddressObject := JsonToken.AsObject()
        else
            if JsonObject.Get(HomeAddressPropertyTxt, JsonToken) and JsonToken.IsObject() then
                BusinessAddressObject := JsonToken.AsObject();

        if JsonToken.IsObject() then begin
            O365Records.Address := CopyStr(GetJsonValue(BusinessAddressObject, StreetPropertyTxt), 1, MaxStrLen(O365Records.Address));
            O365Records.City := CopyStr(GetJsonValue(BusinessAddressObject, CityPropertyTxt), 1, MaxStrLen(O365Records.City));
            O365Records."Post Code" := CopyStr(GetJsonValue(BusinessAddressObject, PostalCodePropertyTxt), 1, MaxStrLen(O365Records."Post Code"));
            O365Records."Country/Region Code" := CopyStr(GetJsonValue(BusinessAddressObject, CountryOrRegionPropertyTxt), 1, MaxStrLen(O365Records."Country/Region Code"));
        end;
    end;

    local procedure GetJsonValue(JsonObject: JsonObject; PropertyName: Text): Text
    var
        JsonToken: JsonToken;
    begin
        if JsonObject.Get(PropertyName, JsonToken) and JsonToken.IsValue() and not JsonToken.AsValue().IsNull() then
            exit(JsonToken.AsValue().AsText());
        exit('');
    end;

    local procedure GetPrimaryEmailAddress(JsonObject: JsonObject): Text
    var
        JsonToken: JsonToken;
        EmailObject: JsonObject;
    begin
        if JsonObject.Get(PrimaryEmailAddressPropertyTxt, JsonToken) and JsonToken.IsObject() then begin
            EmailObject := JsonToken.AsObject();
            exit(CopyStr(GetJsonValue(EmailObject, AddressPropertyTxt), 1, 250));
        end;
        exit('');
    end;

    local procedure GetBusinessPhone(JsonObject: JsonObject): Text
    var
        JsonToken: JsonToken;
        JsonArray: JsonArray;
        PhoneToken: JsonToken;
    begin
        if JsonObject.Get(BusinessPhonesPropertyTxt, JsonToken) and JsonToken.IsArray() then begin
            JsonArray := JsonToken.AsArray();
            if JsonArray.Count() > 0 then begin
                JsonArray.Get(0, PhoneToken);
                if PhoneToken.IsValue() then
                    exit(CopyStr(PhoneToken.AsValue().AsText(), 1, 30));
            end;
        end;
        exit('');
    end;

    local procedure GetDateTimeValue(JsonObject: JsonObject; PropertyName: Text): DateTime
    var
        JsonToken: JsonToken;
        DateTimeText: Text;
        DateTimeValue: DateTime;
    begin
        if JsonObject.Get(PropertyName, JsonToken) and JsonToken.IsValue() and not JsonToken.AsValue().IsNull() then begin
            DateTimeText := JsonToken.AsValue().AsText();
            if Evaluate(DateTimeValue, DateTimeText, 9) then
                exit(DateTimeValue);
        end;
        exit(0DT);
    end;

    local procedure GetCategoriesAsText(JsonObject: JsonObject): Text
    var
        JsonToken: JsonToken;
        JsonArray: JsonArray;
        CategoryToken: JsonToken;
        Categories: Text;
        i: Integer;
    begin
        if JsonObject.Get(CategoriesPropertyTxt, JsonToken) and JsonToken.IsArray() then begin
            JsonArray := JsonToken.AsArray();
            for i := 0 to JsonArray.Count() - 1 do begin
                JsonArray.Get(i, CategoryToken);
                if Categories <> '' then
                    Categories += ', ';
                if CategoryToken.IsValue() then
                    Categories += CategoryToken.AsValue().AsText();
            end;
        end;
        exit(CopyStr(Categories, 1, 250));
    end;

    local procedure HandleErrorResponse(JsonResponse: Text; HttpStatusCode: Integer)
    var
        JsonToken: JsonToken;
        JsonObject: JsonObject;
        ErrorObject: JsonObject;
        ErrorCode: Text;
        ErrorMessage: Text;
    begin
        if JsonObject.ReadFrom(JsonResponse) then begin
            if JsonObject.Get(ErrorPropertyTxt, JsonToken) then begin
                ErrorObject := JsonToken.AsObject();
                ErrorCode := GetJsonValue(ErrorObject, ErrorCodePropertyTxt);
                ErrorMessage := GetJsonValue(ErrorObject, ErrorMessagePropertyTxt);
                Session.LogMessage('0000QTL', StrSubstNo(HttpStatusErrorLogTxt, HttpStatusCode, ErrorCode, ErrorMessage), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', getTracecat());
                case HttpStatusCode of
                    401:
                        Error(Http401UnauthorizedErr, ErrorMessage);
                    403:
                        Error(Http403ForbiddenErr, ErrorMessage);
                    429:
                        Error(Http429TooManyRequestsErr, ErrorMessage);
                    500:
                        Error(Http500InternalServerErr, ErrorMessage);
                    502:
                        Error(Http502BadGatewayErr, ErrorMessage);
                    503:
                        Error(Http503ServiceUnavailableErr, ErrorMessage);
                    else
                        Error(HttpGenericErr, HttpStatusCode, ErrorMessage);
                end;
            end else
                Error(HttpUnexpectedResponseErr, HttpStatusCode);
        end else
            Error(HttpParseErrorErr, HttpStatusCode);
    end;

    procedure GetLastSyncStartDateTime(): DateTime
    begin
        exit(SyncStartDateTime);
    end;

    local procedure GetSecondaryEmailAddress(JsonObject: JsonObject): Text
    var
        JsonToken: JsonToken;
        JsonArray: JsonArray;
        EmailToken: JsonToken;
        EmailObject: JsonObject;
    begin
        if JsonObject.Get(EmailAddressesPropertyTxt, JsonToken) and JsonToken.IsArray() then begin
            JsonArray := JsonToken.AsArray();
            if JsonArray.Count() > 1 then begin
                JsonArray.Get(1, EmailToken); // Get second email
                if EmailToken.IsObject() then begin
                    EmailObject := EmailToken.AsObject();
                    exit(CopyStr(GetJsonValue(EmailObject, AddressPropertyTxt), 1, 250));
                end;
            end;
        end;
        exit('');
    end;

    local procedure GetHomePhone(JsonObject: JsonObject): Text
    var
        JsonToken: JsonToken;
        JsonArray: JsonArray;
        PhoneToken: JsonToken;
    begin
        if JsonObject.Get(HomePhnesPropertyTxt, JsonToken) and JsonToken.IsArray() then begin
            JsonArray := JsonToken.AsArray();
            if JsonArray.Count() > 0 then begin
                JsonArray.Get(0, PhoneToken);
                if PhoneToken.IsValue() then
                    exit(CopyStr(PhoneToken.AsValue().AsText(), 1, 30));
            end;
        end;
        exit('');
    end;

    procedure GetLastSyncCreatedCount(): Integer
    begin
        exit(LastSyncCreatedCount);
    end;

    local procedure CompareAndQueueContacts(var O365Records: Record "O365 Contact"; ContactFilterText: Text)
    var
        LocalContact: Record Contact;
        GraphEmails: List of [Text];
        LocalEmails: List of [Text];
    begin
        NextEntryNo := 1;  // Initialize counter

        if O365Records.FindSet() then
            repeat
                if O365Records."Email Address" <> '' then
                    if not GraphEmails.Contains(O365Records."Email Address") then
                        GraphEmails.Add(O365Records."Email Address");
            until O365Records.Next() = 0;

        // Build Set B: Local contact emails
        LocalContact.Reset();
        LocalContact.SetView(ContactFilterText);
        LocalContact.SetRange(Type, LocalContact.Type::Person);
        LocalContact.SetRange("Privacy Blocked", false);
        LocalContact.SetFilter("E-Mail", '<>%1', '');
        if LocalContact.FindSet() then
            repeat
                if not LocalEmails.Contains(LocalContact."E-Mail") then
                    LocalEmails.Add(LocalContact."E-Mail");
            until LocalContact.Next() = 0;
        if O365Records.FindSet() then
            repeat
                if (O365Records."Email Address" <> '') and not LocalEmails.Contains(O365Records."Email Address") then
                    if not ContactAlreadyInTempQueue(O365Records."Email Address") then begin
                        Clear(TempSyncQueue);
                        TempSyncQueue."Entry No." := NextEntryNo;
                        NextEntryNo += 1;
                        TempSyncQueue.CopyFromO365Contact(O365Records, TempSyncQueue."Sync Direction"::"To BC");
                        TempSyncQueue.Insert(false);
                    end;
            until O365Records.Next() = 0;

        LocalContact.SetRange(Type, LocalContact.Type::Person);
        LocalContact.SetFilter("E-Mail", '<>%1', '');
        if LocalContact.FindSet() then
            repeat
                if not GraphEmails.Contains(LocalContact."E-Mail") then
                    if not ContactAlreadyInTempQueue(LocalContact."E-Mail") then begin
                        Clear(TempSyncQueue);
                        TempSyncQueue."Entry No." := NextEntryNo;
                        NextEntryNo += 1;
                        TempSyncQueue.CopyFromBCContact(LocalContact, TempSyncQueue."Sync Direction"::"To M365");
                        TempSyncQueue.Insert(false);
                    end;
            until LocalContact.Next() = 0;

    end;

    local procedure ContactAlreadyInTempQueue(Email: Text[250]): Boolean
    var
        TempQueueCheck: Record "Contact Sync Queue" temporary;
    begin
        TempQueueCheck.Copy(TempSyncQueue, true); // Copy structure and data
        TempQueueCheck.Reset();
        TempQueueCheck.SetRange("Email Address", Email);
        exit(not TempQueueCheck.IsEmpty());
    end;

    procedure GetContactFolders(AccessToken: SecretText; var OutFolderTable: Record "Contact Sync Folder" temporary)
    var
        HttpClient: HttpClient;
        HttpResponse: HttpResponseMessage;
        JsonResponse: Text;
        JsonObject: JsonObject;
        JsonArray: JsonArray;
        JsonToken: JsonToken;
        FolderObject: JsonObject;
        Uri: Text;
        i: Integer;
        FolderId: Text;
        FolderName: Text;
        EntryNo: Integer;
    begin
        OutFolderTable.DeleteAll();

        if AccessToken.IsEmpty() then
            Error(AccessTokenEmptyMsg);
        Uri := GraphApiUrlTxt;
        Session.LogMessage('0000QTJ', StartingSyncingFoldersTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', getTracecat());
        SetupHttpClientHeaders(HttpClient, AccessToken);

        if HttpClient.Get(Uri, HttpResponse) then begin
            HttpResponse.Content.ReadAs(JsonResponse);
            Session.LogMessage('0000QTK', StrSubstNo(ReceivedFolderResponseTxt, HttpResponse.HttpStatusCode()), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', getTracecat());
            if HttpResponse.IsSuccessStatusCode() then begin
                if not JsonObject.ReadFrom(JsonResponse) then begin
                    Session.LogMessage('0000QU5', InvalidJsonTeleTxt, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', getTracecat());
                    Error(InvalidJsonMsg);
                end;

                if not JsonObject.Get(ValuePropertyTxt, JsonToken) then
                    Error(NoContactFoldersMsg);

                JsonArray := JsonToken.AsArray();
                EntryNo := 0;

                for i := 0 to JsonArray.Count() - 1 do begin
                    JsonArray.Get(i, JsonToken);
                    FolderObject := JsonToken.AsObject();

                    FolderId := GetJsonValue(FolderObject, ParentFolderIdPropertyTxt);
                    FolderName := GetJsonValue(FolderObject, DisplayNamePropertyTxt);

                    if FolderId <> '' then begin
                        EntryNo += 1;
                        OutFolderTable."Entry No." := EntryNo;
                        OutFolderTable."Folder ID" := CopyStr(FolderId, 1, 2048);
                        OutFolderTable."Display Name" := CopyStr(FolderName, 1, 250);
                        OutFolderTable.Insert();
                    end;
                end;
            end else begin
                Session.LogMessage('0000QTL', StrSubstNo(FolderErrorResponseTxt, HttpResponse.HttpStatusCode()), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', getTracecat());
                HandleErrorResponse(JsonResponse, HttpResponse.HttpStatusCode());
            end;

        end else
            Error(NetworkErrorMsg);
    end;

    local procedure SetupHttpClientHeaders(var HttpClient: HttpClient; AccessToken: SecretText)
    begin
        HttpClient.DefaultRequestHeaders.Add(AuthorizationHeaderTxt, SecretStrSubstNo(BearerTokenFormatTxt, AccessToken));
        HttpClient.DefaultRequestHeaders.Add(AcceptHeaderTxt, ApplicationJsonHeaderTxt);
    end;

    local procedure getTracecat(): Text
    begin
        exit(CategoryLbl);
    end;

    procedure CreateFolderinO365(accessToken: SecretText; var OutFolderTable: Record "Contact Sync Folder" temporary; FolderName: Text): Text
    var
        HttpClient: HttpClient;
        HttpResponse: HttpResponseMessage;
        HttpContent: HttpContent;
        JsonResponse: Text;
        JsonObject: JsonObject;
        RequestBody: Text;
        Headers: HttpHeaders;
        FolderId: Text;
    begin
        RequestBody := StrSubstNo(RequestBodyTxt, FolderName);

        HttpContent.WriteFrom(RequestBody);
        HttpContent.GetHeaders(Headers);
        Headers.Clear();
        Headers.Add('Content-Type', ContentTypeLbl);

        SetupHttpClientHeaders(HttpClient, AccessToken);

        if HttpClient.Post(GraphApiUrlTxt, HttpContent, HttpResponse) then begin
            HttpResponse.Content.ReadAs(JsonResponse);
            if HttpResponse.IsSuccessStatusCode() then begin
                if not JsonObject.ReadFrom(JsonResponse) then
                    Session.LogMessage('0000QTM', InvalidJsonTeleTxt + JsonResponse, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', getTracecat());
                FolderId := GetJsonValue(JsonObject, ParentFolderIdPropertyTxt);
                if FolderId <> '' then begin
                    OutFolderTable.DeleteAll();
                    OutFolderTable."Entry No." := 1;
                    OutFolderTable."Folder ID" := CopyStr(FolderId, 1, 2048);
                    OutFolderTable."Display Name" := CopyStr(FolderName, 1, 250);
                    OutFolderTable.Insert();
                    exit(FolderId);
                end else
                    Session.LogMessage('0000QTN', ResponseLbl + JsonResponse, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', getTracecat());
            end else
                HandleErrorResponse(JsonResponse, HttpResponse.HttpStatusCode());
        end else
            Error(NetworkErrorMsg);
    end;
}

