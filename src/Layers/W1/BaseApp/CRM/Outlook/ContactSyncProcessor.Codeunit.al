namespace Microsoft.CRM.Outlook;
using Microsoft.CRM.Contact;

codeunit 7102 "Contact Sync Processor"
{
    var
        SuppressUI: Boolean;
        SyncSuccessLbl: Label '%1 contacts have been synchronized successfully.', Comment = '%1 = Number of synced contacts';
        StartMsg: Label 'This can take a few minutes if you have many contacts.';
        ContactAlreadyExistsLbl: Label 'Contact with this email already exists';
        GraphBatchUriLbl: Label 'https://graph.microsoft.com/v1.0/$batch', Locked = true;
        GraphContactFolderUrlLbl: Label '/me/contactFolders/%1/contacts', Comment = '%1 = Folder ID', Locked = true;
        ContentTypeLbl: Label 'application/json', Locked = true;
        AuthorizationLbl: Label 'Bearer %1', Comment = '%1 = Access token', Locked = true;
        AcceptLbl: Label 'application/json', Locked = true;
        GivenNameLbl: Label 'givenName', Locked = true;
        SurnameLbl: Label 'surname', Locked = true;
        DisplayNameLbl: Label 'displayName', Locked = true;
        CompanyNameLbl: Label 'companyName', Locked = true;
        MobilePhoneLbl: Label 'mobilePhone', Locked = true;
        CategoriesLbl: Label 'categories', Locked = true;
        EmailAddressesLbl: Label 'emailAddresses', Locked = true;
        BusinessPhonesLbl: Label 'businessPhones', Locked = true;
        AddressLbl: Label 'address', Locked = true;
        EmailNameLbl: Label 'name', Locked = true;
        BCCategoryLbl: Label 'Business Central', Locked = true;
        JobTitleLbl: Label 'jobTitle', Locked = true;
        FolderIdLbl: Label 'parentFolderId', Locked = true;
        EmailPrimaryLbl: Label 'primaryEmailAddress', Locked = true;
        InitialsLbl: Label 'initials', Locked = true;
        CityLbl: Label 'city', Locked = true;
        CountyLbl: Label 'state', Locked = true;
        PostCodeLbl: Label 'postalCode', Locked = true;
        CountryorRegionLbl: Label 'countryOrRegion', Locked = true;
        BusinessAddressLbl: Label 'businessAddress', Locked = true;
        BatchSize: Integer;
        // Telemetry/Logging Messages
        SyncStartedTxt: Label 'ProcessBidirectionalSync started with %1 queue entries : Sync Direction %2', Comment = '%1 = queue count, %2 = sync direction', Locked = true;
        NoQueueEntriesTxt: Label 'No contacts in sync queue, exiting', Locked = true;
        SyncingContactToLocalTxt: Label 'Syncing contact  from O365 to Business Central', Locked = true;
        ContactSyncSuccessTxt: Label 'Contact  successfully synced to Business Central', Locked = true;
        NoContactsToSyncMsg: Label 'No contacts were synchronized.', Locked = true;
        ContactSyncFailedTxt: Label 'Failed to sync contact  to Business Central', Locked = true;
        SyncCompletedTxt: Label 'Bidirectional sync completed. Total synced: %1', Comment = '%1 = number of synced contacts', Locked = true;
        CategoryLbl: Label 'Contact Sync', Locked = true, Comment = 'Telemetry category name';
        BatchRequestStartedTxt: Label 'Starting batch request with %1 contacts', Comment = '%1 = batch size', Locked = true;
        BatchRequestCompletedTxt: Label 'Batch request completed with %1 successful, %2 failed', Comment = '%1 = success count, %2 = fail count', Locked = true;
        BatchRequestFailedTxt: Label 'Batch request failed', Locked = true;
        HttpStatusErrorLbl: Label 'HTTP Status: %1', Comment = '%1 = HTTP status code', Locked = true;
        // Batch request JSON keys
        BatchIdLbl: Label 'id', Locked = true;
        BatchMethodLbl: Label 'method', Locked = true;
        BatchUrlLbl: Label 'url', Locked = true;
        BatchHeadersLbl: Label 'headers', Locked = true;
        BatchBodyLbl: Label 'body', Locked = true;
        BatchMethodPostLbl: Label 'POST', Locked = true;
#if not CLEAN29
    [Obsolete('Removed due to Contact Sync redesign, will be deleted in future release.', '29.0')]
    procedure ProcessBidirectionalSync(var TempSyncQueue: Record "Contact Sync Queue" temporary; AccessToken: SecretText)
    begin
    end;
#endif
    procedure ProcessBidirectionalSync(var TempSyncQueue: Record "Contact Sync Queue" temporary; AccessToken: SecretText; FolderId: Text; SyncDirection: Enum "ContactSyncDirection")
    var
        TempBatchQueue: Record "Contact Sync Queue" temporary;
        SyncedCount: Integer;
        BatchCount: Integer;
        ProgressDialog: Dialog;
    begin
        BatchSize := 20; // Microsoft Graph batch limit
        Session.LogMessage('0000QSV', StrSubstNo(SyncStartedTxt, TempSyncQueue.Count(), Format(SyncDirection)), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryLbl);
        if not TempSyncQueue.FindSet() then begin
            Session.LogMessage('0000QSW', NoQueueEntriesTxt, Verbosity::Verbose, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryLbl);
            exit;
        end;

        SyncedCount := 0;
        BatchCount := 0;
        if not SuppressUI then
            ProgressDialog.Open(StartMsg);

        repeat
            case TempSyncQueue."Sync Direction" of
                TempSyncQueue."Sync Direction"::"To BC":
                    if (SyncDirection = SyncDirection::"Full Sync") then begin
                        Session.LogMessage('0000QSX', StrSubstNo(SyncingContactToLocalTxt), Verbosity::Verbose, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryLbl);
                        if SyncContactToBC(TempSyncQueue) then begin
                            Session.LogMessage('0000QSY', StrSubstNo(ContactSyncSuccessTxt), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryLbl);
                            TempSyncQueue."Sync Status" := TempSyncQueue."Sync Status"::Processed;
                            SyncedCount += 1;
                        end else begin
                            Session.LogMessage('0000QSZ', StrSubstNo(ContactSyncFailedTxt), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryLbl);
                            TempSyncQueue."Sync Status" := TempSyncQueue."Sync Status"::Error;
                        end;
                        TempSyncQueue.Modify(false);
                    end;

                TempSyncQueue."Sync Direction"::"To M365":
                    begin
                        // Add to batch queue
                        TempBatchQueue.TransferFields(TempSyncQueue);
                        TempBatchQueue.Insert(false);
                        BatchCount += 1;
                        // Process batch when we reach 20 records or end of queue
                        if BatchCount >= BatchSize then begin
                            SyncedCount += ProcessBatchToO365(TempBatchQueue, TempSyncQueue, AccessToken, FolderId);
                            TempBatchQueue.DeleteAll();
                            BatchCount := 0;
                        end;
                    end;
            end;
        until TempSyncQueue.Next() = 0;

        // Process remaining batch
        if BatchCount > 0 then
            SyncedCount += ProcessBatchToO365(TempBatchQueue, TempSyncQueue, AccessToken, FolderId);

        if not SuppressUI then
            ProgressDialog.Close();
        Session.LogMessage('0000QT3', StrSubstNo(SyncCompletedTxt, SyncedCount), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryLbl);
        if not SuppressUI then
            if SyncedCount > 0 then
                Message(SyncSuccessLbl, SyncedCount)
            else
                Message(NoContactsToSyncMsg);
    end;

    [NonDebuggable]
    local procedure ProcessBatchToO365(var TempBatchQueue: Record "Contact Sync Queue" temporary; var TempSyncQueue: Record "Contact Sync Queue" temporary; AccessToken: SecretText; FolderId: Text): Integer
    var
        HttpClient: HttpClient;
        HttpContent: HttpContent;
        HttpResponse: HttpResponseMessage;
        BatchRequest: JsonObject;
        RequestsArray: JsonArray;
        ResponseJson: JsonObject;
        ResponsesArray: JsonArray;
        ResponseToken: JsonToken;
        BatchJsonText: Text;
        ResponseText: Text;
        Headers: HttpHeaders;
        RequestId: Integer;
        SuccessCount: Integer;
        FailCount: Integer;
        StatusCode: Integer;
    begin
        if not TempBatchQueue.FindSet() then
            exit(0);
        Session.LogMessage('0000QT8', StrSubstNo(BatchRequestStartedTxt, TempBatchQueue.Count()), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryLbl);

        RequestId := 1;
        repeat
            RequestsArray.Add(BuildBatchRequestItem(TempBatchQueue, FolderId, RequestId));
            RequestId += 1;
        until TempBatchQueue.Next() = 0;

        BatchRequest.Add('requests', RequestsArray);
        BatchRequest.WriteTo(BatchJsonText);

        HttpContent.WriteFrom(BatchJsonText);
        HttpContent.GetHeaders(Headers);
        Headers.Clear();
        Headers.Add('Content-Type', ContentTypeLbl);

        HttpClient.DefaultRequestHeaders.Add('Authorization', SecretStrSubstNo(AuthorizationLbl, AccessToken));
        HttpClient.DefaultRequestHeaders.Add('Accept', AcceptLbl);

        if not HttpClient.Post(GraphBatchUriLbl, HttpContent, HttpResponse) then begin
            // Mark all as error
            TempBatchQueue.SetLoadFields("Sync Status", "Error Message");
            if TempBatchQueue.FindSet() then
                repeat
                    if TempSyncQueue.Get(TempBatchQueue."Entry No.") then begin
                        TempSyncQueue."Sync Status" := TempSyncQueue."Sync Status"::Error;
                        TempSyncQueue."Error Message" := BatchRequestFailedTxt;
                        TempSyncQueue.Modify(false);
                    end;
                until TempBatchQueue.Next() = 0;
            exit(0);
        end;

        HttpResponse.Content.ReadAs(ResponseText);
        ResponseJson.ReadFrom(ResponseText);

        // Process batch responses
        SuccessCount := 0;
        FailCount := 0;

        if ResponseJson.Get('responses', ResponseToken) then begin
            ResponsesArray := ResponseToken.AsArray();
            TempBatchQueue.FindSet();
            RequestId := 1;

            repeat
                if GetBatchResponseStatus(ResponsesArray, RequestId, StatusCode) then
                    if TempSyncQueue.Get(TempBatchQueue."Entry No.") then begin
                        if (StatusCode >= 200) and (StatusCode < 300) then begin
                            TempSyncQueue."Sync Status" := TempSyncQueue."Sync Status"::Processed;
                            SuccessCount += 1;
                        end else begin
                            TempSyncQueue."Sync Status" := TempSyncQueue."Sync Status"::Error;
                            TempSyncQueue."Error Message" := StrSubstNo(HttpStatusErrorLbl, StatusCode);
                            FailCount += 1;
                        end;
                        TempSyncQueue.Modify(false);
                    end;
                RequestId += 1;
            until TempBatchQueue.Next() = 0;
        end;

        Session.LogMessage('0000QT9', StrSubstNo(BatchRequestCompletedTxt, SuccessCount, FailCount), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryLbl);
        exit(SuccessCount);
    end;

    local procedure BuildBatchRequestItem(Contact: Record "Contact Sync Queue"; FolderId: Text; RequestId: Integer): JsonObject
    var
        RequestItem: JsonObject;
        HeadersObject: JsonObject;
        BodyObject: JsonObject;
        BodyText: Text;
    begin
        BodyText := BuildContactJsonBody(Contact, FolderId);
        BodyObject.ReadFrom(BodyText);

        RequestItem.Add(BatchIdLbl, Format(RequestId));
        RequestItem.Add(BatchMethodLbl, BatchMethodPostLbl);
        RequestItem.Add(BatchUrlLbl, StrSubstNo(GraphContactFolderUrlLbl, FolderId));

        HeadersObject.Add('Content-Type', ContentTypeLbl);
        RequestItem.Add(BatchHeadersLbl, HeadersObject);
        RequestItem.Add(BatchBodyLbl, BodyObject);

        exit(RequestItem);
    end;

    local procedure GetBatchResponseStatus(ResponsesArray: JsonArray; RequestId: Integer; var StatusCode: Integer): Boolean
    var
        ResponseToken: JsonToken;
        ResponseObject: JsonObject;
        IdToken: JsonToken;
        StatusToken: JsonToken;
        i: Integer;
    begin
        // Responses are typically returned in the same order as requests
        // Try direct index access first (RequestId is 1-based, array is 0-based)
        if ResponsesArray.Get(RequestId - 1, ResponseToken) then begin
            ResponseObject := ResponseToken.AsObject();
            if ResponseObject.Get('id', IdToken) then
                if IdToken.AsValue().AsText() = Format(RequestId) then
                    if ResponseObject.Get('status', StatusToken) then begin
                        StatusCode := StatusToken.AsValue().AsInteger();
                        exit(true);
                    end;
        end;

        // Fallback to linear search if direct access didn't match (order not guaranteed)
        for i := 0 to ResponsesArray.Count() - 1 do begin
            ResponsesArray.Get(i, ResponseToken);
            ResponseObject := ResponseToken.AsObject();

            if ResponseObject.Get('id', IdToken) then
                if IdToken.AsValue().AsText() = Format(RequestId) then
                    if ResponseObject.Get('status', StatusToken) then begin
                        StatusCode := StatusToken.AsValue().AsInteger();
                        exit(true);
                    end;
        end;
        exit(false);
    end;

    local procedure SyncContactToBC(var TempSyncQueue: Record "Contact Sync Queue" temporary): Boolean
    var
        Contact: Record Contact;
    begin
        // Check if contact already exists
        Contact.Reset();
        Contact.SetRange("E-Mail", CopyStr(TempSyncQueue."Email Address", 1, MaxStrLen(Contact."E-Mail")));
        Contact.SetRange(Type, Contact.Type::Person);
        if Contact.FindFirst() then begin
            TempSyncQueue."Error Message" := ContactAlreadyExistsLbl;
            exit(false); // Contact already exists
        end;

        // Create new contact in BC
        Contact.Init();
        Contact."No." := '';
        Contact.Type := Contact.Type::Person;
        if TempSyncQueue."Display Name" <> '' then
            Contact.Name := CopyStr(TempSyncQueue."Display Name", 1, MaxStrLen(Contact.Name))
        else
            Contact.Name := CopyStr(TempSyncQueue."Given Name" + ' ' + TempSyncQueue.Surname, 1, MaxStrLen(Contact.Name));
        Contact."First Name" := CopyStr(TempSyncQueue."Given Name", 1, MaxStrLen(Contact."First Name"));
        Contact.Surname := CopyStr(TempSyncQueue.Surname, 1, MaxStrLen(Contact.Surname));
        Contact."E-Mail" := CopyStr(TempSyncQueue."Email Address", 1, MaxStrLen(Contact."E-Mail"));
        Contact."Job Title" := CopyStr(TempSyncQueue."Job Title", 1, MaxStrLen(Contact."Job Title"));
        Contact."Company Name" := CopyStr(TempSyncQueue."Company Name", 1, MaxStrLen(Contact."Company Name"));
        Contact."Phone No." := CopyStr(TempSyncQueue."Business Phone", 1, MaxStrLen(Contact."Phone No."));
        Contact."Mobile Phone No." := CopyStr(TempSyncQueue."Mobile Phone", 1, MaxStrLen(Contact."Mobile Phone No."));
        Contact.Address := CopyStr(TempSyncQueue.Address, 1, MaxStrLen(Contact.Address));
        Contact.City := CopyStr(TempSyncQueue.City, 1, MaxStrLen(Contact.City));
        Contact.County := CopyStr(TempSyncQueue.County, 1, MaxStrLen(Contact.County));
        Contact."Post Code" := CopyStr(TempSyncQueue."Post Code", 1, MaxStrLen(Contact."Post Code"));
        Contact."Country/Region Code" := CopyStr(TempSyncQueue."Country/Region Code", 1, MaxStrLen(Contact."Country/Region Code"));
        if Contact.Insert(true) then begin
            TempSyncQueue."BC Contact No." := Contact."No.";
            exit(true);
        end;
        exit(false);
    end;

    local procedure BuildContactJsonBody(Contact: Record "Contact Sync Queue"; FolderId: Text): Text
    var
        JsonObject: JsonObject;
        JsonText: Text;
    begin
        JsonObject.Add(GivenNameLbl, Contact."Given Name");
        JsonObject.Add(SurnameLbl, Contact.Surname);
        if Contact."Display Name" <> '' then
            JsonObject.Add(DisplayNameLbl, Contact."Display Name")
        else
            JsonObject.Add(DisplayNameLbl, Contact."Given Name" + ' ' + Contact.Surname);
        JsonObject.Add(CompanyNameLbl, Contact."Company Name");
        JsonObject.Add(InitialsLbl, Contact.Initials);
        JsonObject.Add(MobilePhoneLbl, Contact."Mobile Phone");
        JsonObject.Add(JobTitleLbl, Contact."Job Title");
        JsonObject.Add(CategoriesLbl, BuildCategoriesArray());
        JsonObject.Add(FolderIdLbl, FolderId);

        // Add email addresses
        if Contact."Email Address" <> '' then
            JsonObject.Add(EmailPrimaryLbl, BuildPrimaryEmailArray(Contact."Email Address"));
        if Contact."Email 2" <> '' then
            JsonObject.Add(EmailAddressesLbl, BuildEmailArray(Contact."Email 2"));
        // Add business phones
        if Contact."Business Phone" <> '' then
            JsonObject.Add(BusinessPhonesLbl, BuildPhoneArray(Contact."Business Phone"));
        JsonObject.Add(BusinessAddressLbl, BuildAddressObject(Contact));
        JsonObject.WriteTo(JsonText);
        exit(JsonText);
    end;

    local procedure BuildAddressObject(var Contact: Record "Contact Sync Queue"): JsonObject
    var
        AddressObject: JsonObject;
    begin
        AddressObject.Add(CityLbl, Contact.City);
        AddressObject.Add(CountyLbl, Contact.County);
        AddressObject.Add(PostCodeLbl, Contact."Post Code");
        AddressObject.Add(CountryorRegionLbl, Contact."Country/Region Code");
        exit(AddressObject);
    end;

    local procedure BuildEmailArray(EmailAddress: Text[80]): JsonArray
    var
        EmailArray: JsonArray;
        EmailObject: JsonObject;
    begin
        EmailObject.Add(AddressLbl, EmailAddress);
        EmailObject.Add(EmailNameLbl, EmailAddress);
        EmailArray.Add(EmailObject);
        exit(EmailArray);
    end;

    local procedure BuildPrimaryEmailArray(EmailAddress: Text[80]): JsonObject
    var
        EmailObject: JsonObject;
    begin
        EmailObject.Add(AddressLbl, EmailAddress);
        EmailObject.Add(EmailNameLbl, EmailAddress);
        exit(EmailObject);
    end;

    local procedure BuildPhoneArray(PhoneNo: Text[30]): JsonArray
    var
        PhoneArray: JsonArray;
    begin
        PhoneArray.Add(PhoneNo);
        exit(PhoneArray);
    end;

    local procedure BuildCategoriesArray(): JsonArray
    var
        CategoriesArray: JsonArray;
    begin
        CategoriesArray.Add(BCCategoryLbl);
        exit(CategoriesArray);
    end;

    /// <summary>
    /// Suppresses UI elements (dialogs and messages) during execution.
    /// Use this method in test scenarios to prevent unexpected UI prompts.
    /// </summary>
    /// <param name="Suppress">Set to true to suppress UI elements.</param>
    procedure SetSuppressUI(Suppress: Boolean)
    begin
        SuppressUI := Suppress;
    end;

    /// <summary>
    /// Returns whether UI suppression is currently enabled.
    /// </summary>
    /// <returns>True if UI is suppressed, false otherwise.</returns>
    procedure IsSuppressUI(): Boolean
    begin
        exit(SuppressUI);
    end;
}