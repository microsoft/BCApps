namespace Microsoft.CRM.Outlook;
using Microsoft.CRM.Contact;

codeunit 7102 "Contact Sync Processor"
{
    var
        SyncSuccessLbl: Label '%1 contacts have been synchronized successfully.', Comment = '%1 = Number of synced contacts';
        StartMsg: Label 'Synchronization process may take a few minutes depending on the number of contacts to sync.', Locked = true;
        ContactAlreadyExistsLbl: Label 'Contact with this email already exists';
        GraphApiUriLbl: Label 'https://graph.microsoft.com/v1.0/me/contacts', Locked = true;
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
        // Telemetry/Logging Messages
        SyncStartedTxt: Label 'ProcessBidirectionalSync started with %1 queue entries', Comment = '%1 = queue count', Locked = true;
        NoQueueEntriesTxt: Label 'No contacts in sync queue, exiting', Locked = true;
        SyncingContactToLocalTxt: Label 'Syncing contact  from O365 to Business Central', Locked = true;
        ContactSyncSuccessTxt: Label 'Contact  successfully synced to Business Central', Locked = true;
        ContactSyncFailedTxt: Label 'Failed to sync contact  to Business Central', Locked = true;
        SyncingContactToO365Txt: Label 'Syncing contact  from Business Central to O365', Locked = true;
        ContactCreatedInGraphTxt: Label 'Contact successfully created in O365', Locked = true;
        ContactCreationFailedTxt: Label 'Failed to create contact  in O365', Locked = true;
        SyncCompletedTxt: Label 'Bidirectional sync completed. Total synced: %1', Comment = '%1 = number of synced contacts', Locked = true;
        CreatingContactInGraphTxt: Label 'Creating contact in Microsoft Graph', Locked = true;
        BuildingContactJsonTxt: Label 'Building JSON body for contact %1', Comment = '%1 = contact name', Locked = true;
        HttpPostFailedTxt: Label 'HTTP POST request failed for contact %1', Comment = '%1 = contact name', Locked = true;
        GraphConnectionErrorTxt: Label 'Unable to connect to Microsoft Graph API for contact %1', Comment = '%1 = contact name', Locked = true;
        CategoryLbl: Label 'Contact Sync', Locked = true, Comment = 'Telemetry category name';

    procedure ProcessBidirectionalSync(var TempSyncQueue: Record "Contact Sync Queue" temporary; AccessToken: SecretText)
    var
        SyncedCount: Integer;
        ProgressDialog: Dialog;
    begin
        Session.LogMessage('0000QSV', StrSubstNo(SyncStartedTxt, TempSyncQueue.Count()), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryLbl);
        if not TempSyncQueue.FindSet() then begin
            Session.LogMessage('0000QSW', NoQueueEntriesTxt, Verbosity::Verbose, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryLbl);
            exit;
        end;

        SyncedCount := 0;
        ProgressDialog.Open(StartMsg);

        repeat
            case TempSyncQueue."Sync Direction" of
                TempSyncQueue."Sync Direction"::"To BC":
                    begin
                        Session.LogMessage('0000QSX', StrSubstNo(SyncingContactToLocalTxt), Verbosity::Verbose, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryLbl);
                        if SyncContactToBC(TempSyncQueue) then begin
                            Session.LogMessage('0000QSY', StrSubstNo(ContactSyncSuccessTxt), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryLbl);
                            TempSyncQueue."Sync Status" := TempSyncQueue."Sync Status"::Processed;
                            SyncedCount += 1;
                        end else begin
                            Session.LogMessage('0000QSZ', StrSubstNo(ContactSyncFailedTxt), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryLbl);
                            TempSyncQueue."Sync Status" := TempSyncQueue."Sync Status"::Error;
                        end;
                    end;

                TempSyncQueue."Sync Direction"::"To M365":
                    begin
                        Session.LogMessage('0000QT0', StrSubstNo(SyncingContactToO365Txt), Verbosity::Verbose, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryLbl);
                        if SyncContactToO365(TempSyncQueue, AccessToken) then begin
                            Session.LogMessage('0000QT1', StrSubstNo(ContactCreatedInGraphTxt), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryLbl);
                            TempSyncQueue."Sync Status" := TempSyncQueue."Sync Status"::Processed;
                            SyncedCount += 1;
                        end else begin
                            Session.LogMessage('0000QT2', StrSubstNo(ContactCreationFailedTxt), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryLbl);
                            TempSyncQueue."Sync Status" := TempSyncQueue."Sync Status"::Error;
                        end;
                    end;
            end;

            TempSyncQueue.Modify(false);
        until TempSyncQueue.Next() = 0;

        ProgressDialog.Close();
        Session.LogMessage('0000QT3', StrSubstNo(SyncCompletedTxt, SyncedCount), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryLbl);
        if SyncedCount > 0 then
            Message(SyncSuccessLbl, SyncedCount);
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

    local procedure SyncContactToO365(var TempSyncQueue: Record "Contact Sync Queue" temporary; AccessToken: SecretText): Boolean
    begin
        if TempSyncQueue."BC Contact No." <> '' then
            if CreateContactInO365(TempSyncQueue, AccessToken) then
                exit(true)
            else
                exit(false);
        exit(false);
    end;

    local procedure CreateContactInO365(Contact: Record "Contact Sync Queue"; AccessToken: SecretText): Boolean
    var
        HttpClient: HttpClient;
        HttpContent: HttpContent;
        HttpResponse: HttpResponseMessage;
        JsonBody: Text;
        Uri: Text;
        Headers: HttpHeaders;
    begin
        Session.LogMessage('0000QT4', StrSubstNo(CreatingContactInGraphTxt), Verbosity::Verbose, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryLbl);
        Uri := GraphApiUriLbl;

        // Build JSON body for contact
        Session.LogMessage('0000QT5', StrSubstNo(BuildingContactJsonTxt), Verbosity::Verbose, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryLbl);
        JsonBody := BuildContactJsonBody(Contact);

        HttpContent.WriteFrom(JsonBody);
        HttpContent.GetHeaders(Headers);
        Headers.Clear();
        Headers.Add('Content-Type', ContentTypeLbl);

        HttpClient.DefaultRequestHeaders.Add('Authorization', SecretStrSubstNo(AuthorizationLbl, AccessToken));
        HttpClient.DefaultRequestHeaders.Add('Accept', AcceptLbl);

        if HttpClient.Post(Uri, HttpContent, HttpResponse) then begin
            if not HttpResponse.IsSuccessStatusCode() then begin
                Session.LogMessage('0000QT6', StrSubstNo(HttpPostFailedTxt), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryLbl);
                exit(false);
            end;
        end else begin
            Session.LogMessage('0000QT7', StrSubstNo(GraphConnectionErrorTxt), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryLbl);
            exit(false);
        end;
        exit(true);
    end;

    local procedure BuildContactJsonBody(Contact: Record "Contact Sync Queue"): Text
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
        JsonObject.Add(MobilePhoneLbl, Contact."Mobile Phone");
        JsonObject.Add(CategoriesLbl, BuildCategoriesArray());

        // Add email addresses
        if Contact."Email Address" <> '' then
            JsonObject.Add(EmailAddressesLbl, BuildEmailArray(Contact."Email Address"));

        // Add business phones
        if Contact."Business Phone" <> '' then
            JsonObject.Add(BusinessPhonesLbl, BuildPhoneArray(Contact."Business Phone"));

        JsonObject.WriteTo(JsonText);
        exit(JsonText);
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
}
