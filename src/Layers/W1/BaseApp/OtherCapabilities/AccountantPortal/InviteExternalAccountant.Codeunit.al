namespace Microsoft.AccountantPortal;

using System;
using System.Text;
using System.Azure.Identity;
using System.Environment.Configuration;
using System.Integration;
using System.Utilities;

codeunit 9033 "Invite External Accountant"
{

    trigger OnRun()
    begin
    end;

    var
        UrlHelper: Codeunit "Url Helper";

        ErrorAcquiringTokenErr: Label 'Failed to acquire an access token.  This is necessary to invite the external accountant.  Contact your administrator.', Locked = true;
        InviteReedemUrlTxt: Label 'inviteRedeemUrl', Locked = true;
        InvitedUserIdTxt: Label 'invitedUser', Locked = true;
        IdTxt: Label 'id', Locked = true;
        ConsumedUnitsTxt: Label 'consumedUnits', Locked = true;
        ErrorTxt: Label 'error', Locked = true;
        MessageTxt: Label 'message', Locked = true;
        ValueTxt: Label 'value', Locked = true;
        SkuIdTxt: Label 'skuId', Locked = true;
        PrepaidUnitsTxt: Label 'prepaidUnits', Locked = true;
        EnabledUnitsTxt: Label 'enabled', Locked = true;
        GlobalAdministratorRoleTemplateIdTxt: Label '62e90394-69f5-4237-9190-012177145e10', Locked = true;
        UserAdministratorRoleTemplateIdTxt: Label 'fe930be7-5e62-47db-91af-98c3a49a38b1', Locked = true;
        ExternalAccountantLicenseSkuIdTxt: Label '9a1e33ed-9697-43f3-b84c-1b0959dbb1d4', Locked = true;
        InviteExternalAccountantTelemetryCategoryTxt: Label 'AL Dynamics 365 Invite External Accountant', Locked = true;
        InviteExternalAccountantTelemetryStartTxt: Label 'Invite External Accountant process started.', Locked = true;
        InviteExternalAccountantTelemetryEndTxt: Label 'Invite External Accountant process ended with the following result:  %1:  License is %2.', Locked = true;
        InviteExternalAccountantTelemetryLicenseFailTxt: Label 'Invite External Accountant wizard failed to start due to there being no external accountant license available.', Locked = true;
        InviteExternalAccountantTelemetryAADPermissionFailTxt: Label 'Invite External Accountant wizard failed to start due to the user not having the necessary Microsoft Entra permissions.', Locked = true;
        InviteExternalAccountantTelemetryUserTablePermissionFailTxt: Label 'Invite External Accountant wizard failed to start due to the session not being admin or the user being Super in all companies.', Locked = true;
        InviteExternalAccountantTelemetryCreateNewUserSuccessTxt: Label 'Invite External Accountant wizard successfully created a new user.', Locked = true;
        InviteExternalAccountantTelemetryCreateNewUserFailedTxt: Label 'Invite External Accountant wizard was unable to create a new user.', Locked = true;
        InviteExternalAccountantWizardFailedTxt: Label 'Invite External Accountant wizard has failed on step %1, ErrorMessage %2.', Locked = true;
        InvokeWebRequestFailedTxt: Label 'Invoking web request has failed. Status %1, Message %2', Locked = true;
        InvokeWebRequestFailedDetailedTxt: Label 'Invoking web request has failed. Status %1, Message %2, Response Details %3', Locked = true;
        InsufficientDataReturnedFromInvitationsApiTxt: Label 'Insufficient information was returned when inviting the user. Please contact your administrator.';
        WidsClaimNameTok: Label 'WIDS', Locked = true;
        ExternalAccountantLicenseAvailabilityErr: Label 'Failed to determine if an External Accountant license is available. Please try again later.';

    [Scope('OnPrem')]
    procedure InvokeInvitationsRequest(DisplayName: Text; EmailAddress: Text; WebClientUrl: Text; var InvitedUserId: Guid; var InviteReedemUrl: Text; var ErrorMessage: Text): Boolean
    var
        JSONManagement: Codeunit "JSON Management";
        JsonObject: DotNet JObject;
        InviteUserIdJsonObject: DotNet JObject;
        InviteUserIdObjectValue: Text;
        ResponseContent: Text;
        Body: Text;
        FoundInviteRedeemUrlValue: Boolean;
        FoundInvitedUserObjectValue: Boolean;
        FoundInviteUserIdValue: Boolean;
    begin
        Body := '{';
        Body := Body + '"invitedUserDisplayName" : "' + DisplayName + '",';
        Body := Body + '"invitedUserEmailAddress" : "' + EmailAddress + '",';
        Body := Body + '"inviteRedirectUrl" : "' + WebClientUrl + '",';
        Body := Body + '"sendInvitationMessage" : "false"';
        Body := Body + '}';

        if InvokeRequestWithGraphAccessToken(GetGraphInvitationsUrl(), 'POST', Body, ResponseContent) then begin
            JSONManagement.InitializeObject(ResponseContent);
            JSONManagement.GetJSONObject(JsonObject);
            FoundInviteRedeemUrlValue :=
              JSONManagement.GetStringPropertyValueFromJObjectByName(JsonObject, InviteReedemUrlTxt, InviteReedemUrl);
            FoundInvitedUserObjectValue :=
              JSONManagement.GetStringPropertyValueFromJObjectByName(JsonObject, InvitedUserIdTxt, InviteUserIdObjectValue);
            JSONManagement.InitializeObject(InviteUserIdObjectValue);
            JSONManagement.GetJSONObject(InviteUserIdJsonObject);
            FoundInviteUserIdValue := JSONManagement.GetGuidPropertyValueFromJObjectByName(InviteUserIdJsonObject, IdTxt, InvitedUserId);

            if FoundInviteRedeemUrlValue and FoundInvitedUserObjectValue and FoundInviteUserIdValue then
                exit(true);

            ErrorMessage := InsufficientDataReturnedFromInvitationsApiTxt;
            exit(false);
        end;

        ErrorMessage := GetMessageFromErrorJSON(ResponseContent);
        exit(false);
    end;

    [Scope('OnPrem')]
    procedure InvokeUserProfileUpdateRequest(var GuestGraphUser: DotNet UserInfo; CountryLetterCode: Text; var ErrorMessage: Text): Boolean
    var
        Body: Text;
        ResponseContent: Text;
        GraphUserUrl: Text;
    begin
        GraphUserUrl := GetGraphUserUrl() + '/' + GuestGraphUser.ObjectId;
        Body := '{"usageLocation" : "' + CountryLetterCode + '"}';

        // Set usage location on guest user to current tenant's country letter code.
        if InvokeRequestWithGraphAccessToken(GraphUserUrl, 'PATCH', Body, ResponseContent) then
            exit(true);

        ErrorMessage := GetMessageFromErrorJSON(ResponseContent);
        exit(false);
    end;

    [Scope('OnPrem')]
    procedure InvokeUserAssignLicenseRequest(var GraphUser: DotNet UserInfo; TargetLicense: Text; var ErrorMessage: Text): Boolean
    var
        Body: Text;
        ResponseContent: Text;
        Url: Text;
    begin
        Url := GetGraphUserUrl() + '/' + GraphUser.ObjectId + '/assignLicense';

        Body := '{';
        Body := Body + '"addLicenses": [';
        Body := Body + '{';
        Body := Body + '"disabledPlans": [],';
        Body := Body + '"skuId": "' + TargetLicense + '"';
        Body := Body + '}],';
        Body := Body + '"removeLicenses": []';
        Body := Body + '}';

        if InvokeRequestWithGraphAccessToken(Url, 'POST', Body, ResponseContent) then
            exit(true);

        ErrorMessage := GetMessageFromErrorJSON(ResponseContent);
        exit(false);
    end;

    [Scope('OnPrem')]
    procedure InvokeIsExternalAccountantLicenseAvailable(var ErrorMessage: Text; var TargetLicense: Text): Boolean
    var
        JSONManagement: Codeunit "JSON Management";
        JsonObject: DotNet JObject;
        JsonArray: DotNet JArray;
        PrepaidUnitsJsonObject: DotNet JObject;
        NumberSkus: Integer;
        ResponseContent: Text;
        SkuIdValue: Text;
        ConsumedUnitsValue: Decimal;
        PrepaidUnitsValue: Text;
        EnabledUnitsValue: Decimal;
    begin
        if InvokeRequestWithGraphAccessToken(GetGraphSubscribedSkusUrl(), 'GET', '', ResponseContent) then begin
            if not JSONManagement.TryParseJObjectFromString(JsonObject, ResponseContent) then
                Error(ExternalAccountantLicenseAvailabilityErr);

            if not JSONManagement.GetArrayPropertyValueFromJObjectByName(JsonObject, ValueTxt, JsonArray) then
                Error(ExternalAccountantLicenseAvailabilityErr);
            JSONManagement.InitializeCollectionFromJArray(JsonArray);

            NumberSkus := JSONManagement.GetCollectionCount();
            while NumberSkus > 0 do begin
                NumberSkus := NumberSkus - 1;
                if JSONManagement.GetJObjectFromCollectionByIndex(JsonObject, NumberSkus) then begin
                    if not JSONManagement.GetStringPropertyValueFromJObjectByName(JsonObject, SkuIdTxt, SkuIdValue) then
                        Error(ExternalAccountantLicenseAvailabilityErr);
                    if not JSONManagement.GetDecimalPropertyValueFromJObjectByName(JsonObject, ConsumedUnitsTxt, ConsumedUnitsValue) then
                        Error(ExternalAccountantLicenseAvailabilityErr);
                    // Check to see if there is an external accountant license available.
                    if (SkuIdValue = ExternalAccountantLicenseSkuIdTxt) then begin
                        TargetLicense := SkuIdValue;
                        if not JSONManagement.GetStringPropertyValueFromJObjectByName(JsonObject, PrepaidUnitsTxt, PrepaidUnitsValue) then
                            Error(ExternalAccountantLicenseAvailabilityErr);
                        if not JSONManagement.TryParseJObjectFromString(PrepaidUnitsJsonObject, PrepaidUnitsValue) then
                            Error(ExternalAccountantLicenseAvailabilityErr);
                        if not JSONManagement.GetDecimalPropertyValueFromJObjectByName(PrepaidUnitsJsonObject, EnabledUnitsTxt, EnabledUnitsValue) then
                            Error(ExternalAccountantLicenseAvailabilityErr);

                        if ConsumedUnitsValue < EnabledUnitsValue then
                            exit(true);

                        exit(false);
                    end;
                end;
            end;
        end;

        ErrorMessage := GetMessageFromErrorJSON(ResponseContent);
        exit(false);
    end;

    [Scope('OnPrem')]
    procedure InvokeIsUserAdministrator(): Boolean
    var
        ClaimValue: Text;
    begin
        ClaimValue := GetCurrentUserTokenClaim(WidsClaimNameTok);
        if ClaimValue = '' then
            exit(false);

        if StrPos(UpperCase(ClaimValue), UpperCase(GlobalAdministratorRoleTemplateIdTxt)) > 0 then
            exit(true);
        if StrPos(UpperCase(ClaimValue), UpperCase(UserAdministratorRoleTemplateIdTxt)) > 0 then
            exit(true);

        exit(false);
    end;

    local procedure GetCurrentUserTokenClaim(ClaimName: Text): Text
    var
        UserAccountHelper: DotNet NavUserAccountHelper;
    begin
        exit(UserAccountHelper.GetCurrentUserTokenClaim(ClaimName));
    end;

    [Scope('OnPrem')]
    procedure CreateNewUser(InvitedUserId: Guid)
    var
        AzureADUserManagement: Codeunit "Azure AD User Management";
        AzureADGraph: codeunit "Azure AD Graph";
        UserAssignedPlans: DotNet GenericList1;
        GuestGraphUser: DotNet UserInfo;
        NumberOfAssignedPlan: Integer;
        "Count": Integer;
    begin
        repeat
            Sleep(2000);
            Count := Count + 1;

            if AzureADGraph.TryGetUserByObjectId(InvitedUserId, GuestGraphUser) then begin
                AzureADGraph.GetUserAssignedPlans(GuestGraphUser, UserAssignedPlans);

                if (not IsNull(UserAssignedPlans)) then
                    NumberOfAssignedPlan := UserAssignedPlans.Count();
            end;
        until (NumberOfAssignedPlan > 1) or (Count = 10);

        if NumberOfAssignedPlan > 1 then begin
            OnInvitationCreateNewUser(true);
            AzureADUserManagement.CreateNewUserFromGraphUser(GuestGraphUser);
        end else
            OnInvitationCreateNewUser(false);
    end;

    [Scope('OnPrem')]
    procedure IsLicenseAlreadyAssigned(GuestGraphUser: DotNet UserInfo): Boolean
    var
        AzureADGraph: Codeunit "Azure AD Graph";
        UserAssignedPlans: DotNet GenericList1;
    begin
        AzureADGraph.GetUserAssignedPlans(GuestGraphUser, UserAssignedPlans);
        if IsNull(UserAssignedPlans) then
            exit(false);
        exit(UserAssignedPlans.Count() > 0);
    end;

    [Scope('OnPrem')]
    procedure TryGetGuestGraphUser(InvitedUserId: Guid; var GuestGraphUser: DotNet UserInfo): Boolean
    var
        AzureADGraph: codeunit "Azure AD Graph";
        FoundUser: Boolean;
        "Count": Integer;
    begin
        repeat
            Sleep(2000);
            Count := Count + 1;
            FoundUser := AzureADGraph.TryGetUserByObjectId(InvitedUserId, GuestGraphUser);
        until FoundUser or (Count = 10);

        exit(FoundUser);
    end;

    procedure UpdateAssistedSetup()
    var
        GuidedExperience: Codeunit "Guided Experience";
    begin
        GuidedExperience.CompleteAssistedSetup(ObjectType::Page, PAGE::"Invite External Accountant");
    end;

    local procedure InvokeRequestWithGraphAccessToken(Url: Text; Verb: Text; Body: Text; var ResponseContent: Text): Boolean
    begin
        exit(InvokeRequest(Url, Verb, Body, UrlHelper.GetGraphUrl(), ResponseContent));
    end;

    local procedure InvokeRequest(Url: Text; Verb: Text; Body: Text; AuthResourceUrl: Text; var ResponseContent: Text): Boolean
    var
        AzureADMgt: Codeunit "Azure AD Mgt.";
        AzureADTenant: Codeunit "Azure AD Tenant";
        HttpWebRequestMgt: Codeunit "Http Web Request Mgt.";
        HttpStatusCode: DotNet HttpStatusCode;
        ResponseHeaders: DotNet NameValueCollection;
        ResponseErrorMessage: Text;
        ResponseErrorDetails: Text;
        AccessToken: Text;
    begin
        AccessToken := AzureADMgt.GetGuestAccessToken(AuthResourceUrl, AzureADTenant.GetAadTenantId());

        if AccessToken = '' then
            Error(ErrorAcquiringTokenErr);

        HttpWebRequestMgt.Initialize(Url);
        HttpWebRequestMgt.DisableUI();
        HttpWebRequestMgt.SetReturnType('application/json');
        HttpWebRequestMgt.SetContentType('application/json');
        HttpWebRequestMgt.SetMethod(Verb);
        HttpWebRequestMgt.AddHeader('Authorization', 'Bearer ' + AccessToken);
        if Verb <> 'GET' then
            HttpWebRequestMgt.AddBodyAsText(Body);

        if HttpWebRequestMgt.SendRequestAndReadTextResponse(ResponseContent, ResponseErrorMessage, ResponseErrorDetails, HttpStatusCode, ResponseHeaders) then
            exit(true)
        else begin
            Session.LogMessage('0000B3O', StrSubstNo(InvokeWebRequestFailedTxt, HttpStatusCode, ResponseErrorMessage), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', InviteExternalAccountantTelemetryCategoryTxt);

            Session.LogMessage('0000B3P', StrSubstNo(InvokeWebRequestFailedDetailedTxt, HttpStatusCode, ResponseErrorMessage, ResponseErrorDetails), Verbosity::Error, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, 'Category', InviteExternalAccountantTelemetryCategoryTxt);

            exit(false);
        end;
    end;

    local procedure GetMessageFromErrorJSON(ResponseContent: Text): Text
    var
        JSONManagement: Codeunit "JSON Management";
        JsonObject: DotNet JObject;
        ErrorObjectValue: Text;
        MessageValue: Text;
    begin
        JSONManagement.InitializeObject(ResponseContent);
        JSONManagement.GetJSONObject(JsonObject);
        if JSONManagement.GetStringPropertyValueFromJObjectByName(JsonObject, ErrorTxt, ErrorObjectValue) then begin
            JSONManagement.InitializeObject(ErrorObjectValue);
            JSONManagement.GetJSONObject(JsonObject);
            JSONManagement.GetStringPropertyValueFromJObjectByName(JsonObject, MessageTxt, MessageValue);
        end;

        exit(MessageValue);
    end;

    local procedure GetGraphInvitationsUrl(): Text
    begin
        exit(UrlHelper.GetGraphUrl() + 'v1.0/invitations');
    end;

    local procedure GetGraphUserUrl(): Text
    begin
        exit(UrlHelper.GetGraphUrl() + 'v1.0/users');
    end;

    local procedure GetGraphSubscribedSkusUrl(): Text
    begin
        exit(UrlHelper.GetGraphUrl() + 'v1.0/subscribedSkus');
    end;

    procedure SendTelemetryForWizardFailure(stepFailed: Text; ErrorMessage: Text)
    begin
        Session.LogMessage('0000B97', StrSubstNo(InviteExternalAccountantWizardFailedTxt, stepFailed, ErrorMessage), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', InviteExternalAccountantTelemetryCategoryTxt);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Invite External Accountant", 'OnInvitationStart', '', false, false)]
    local procedure SendTelemetryForInvitationStart()
    begin
        Session.LogMessage('0000178', InviteExternalAccountantTelemetryStartTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', InviteExternalAccountantTelemetryCategoryTxt);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Invite External Accountant", 'OnInvitationNoExternalAccountantLicenseFail', '', false, false)]
    local procedure SendTelemetryForInvitationNoExternalAccountantLicenseFail()
    begin
        Session.LogMessage('0000179', InviteExternalAccountantTelemetryLicenseFailTxt, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', InviteExternalAccountantTelemetryCategoryTxt);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Invite External Accountant", 'OnInvitationNoAADPermissionsFail', '', false, false)]
    local procedure SendTelemetryForInvitationNoAADPermissionsFail()
    begin
        Session.LogMessage('000017A', InviteExternalAccountantTelemetryAADPermissionFailTxt, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', InviteExternalAccountantTelemetryCategoryTxt);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Invite External Accountant", 'OnInvitationNoUserTablePermissionsFail', '', false, false)]
    local procedure SendTelemetryForInvitationNoUserTableWritePermissionsFail()
    begin
        Session.LogMessage('00001DK', InviteExternalAccountantTelemetryUserTablePermissionFailTxt, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', InviteExternalAccountantTelemetryCategoryTxt);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Invite External Accountant", 'OnInvitationEnd', '', false, false)]
    local procedure SendTelemetryForInvitationEnd(WasInvitationSuccessful: Boolean; Result: Text; TargetLicense: Text)
    begin
        if WasInvitationSuccessful then
            Session.LogMessage('000017B', StrSubstNo(InviteExternalAccountantTelemetryEndTxt, Result, TargetLicense), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', InviteExternalAccountantTelemetryCategoryTxt)
        else
            Session.LogMessage('000017C', StrSubstNo(InviteExternalAccountantTelemetryEndTxt, Result, TargetLicense), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', InviteExternalAccountantTelemetryCategoryTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Invite External Accountant", 'OnInvitationCreateNewUser', '', false, false)]
    local procedure SendTelemetryForInvitationCreateNewUser(UserCreated: Boolean)
    begin
        if UserCreated then
            Session.LogMessage('00001DL', InviteExternalAccountantTelemetryCreateNewUserSuccessTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', InviteExternalAccountantTelemetryCategoryTxt)
        else
            Session.LogMessage('00001DM', InviteExternalAccountantTelemetryCreateNewUserFailedTxt, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', InviteExternalAccountantTelemetryCategoryTxt);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInvitationCreateNewUser(UserCreated: Boolean)
    begin
        // This event is called when the invitation process tries to create a user.
    end;
}

