// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

using System.Apps;
using System.Azure.KeyVault;
using System.Environment;
using System.Security.Authentication;
using System.Utilities;

/// <summary>
/// Codeunit Shpfy Authentication Mgt. (ID 30199).
/// </summary>
codeunit 30199 "Shpfy Authentication Mgt."
{
    Access = Internal;

    var
        // https://shopify.dev/api/usage/access-scopes
        ScopeTxt: Label 'write_orders,read_all_orders,write_assigned_fulfillment_orders,read_checkouts,write_customers,read_discounts,write_files,write_merchant_managed_fulfillment_orders,write_fulfillments,write_inventory,read_locations,write_products,write_shipping,read_shopify_payments_disputes,read_shopify_payments_payouts,write_returns,write_translations,write_third_party_fulfillment_orders,write_order_edits,write_publications,write_payment_terms,write_draft_orders,read_locales,read_shopify_payments_accounts,read_users,read_markets', Locked = true;
        ShopifyAPIKeyAKVSecretNameLbl: Label 'ShopifyApiKey', Locked = true;
        ShopifyAPISecretAKVSecretNameLbl: Label 'ShopifyApiSecret', Locked = true;
        MissingAPIKeyTelemetryTxt: Label 'The api key has not been initialized.', Locked = true;
        MissingAPISecretTelemetryTxt: Label 'The api secret has not been initialized.', Locked = true;
        CategoryTok: Label 'Shopify Integration', Locked = true;
        NoCallbackErr: Label 'No callback was received from Shopify. Make sure that you haven''t closed the page that says "Waiting for a response - do not close this page", and then try again.';
        HttpRequestBlockedErr: Label 'Shopify connector is not allowed to make HTTP requests when running in a non-production environment.';
        EnableHttpRequestActionLbl: Label 'Allow HTTP requests';
        InvalidShopUrlErr: Label 'The URL must refer to the internal shop location at myshopify.com. It must not be the public URL that customers use, such as myshop.com.';
        NotSupportedOnPremErr: Label 'Shopify connector is only supported in SaaS environments.';
        RefreshTokenExpiredErr: Label 'The Shopify access token for store "%1" has expired and could not be refreshed automatically. Open the Shopify Shop card and reconnect the store to continue.', Comment = '%1 = Store';
        TokenExchangeGrantTypeTok: Label 'urn:ietf:params:oauth:grant-type:token-exchange', Locked = true;
        RefreshTokenGrantTypeTok: Label 'refresh_token', Locked = true;
        OfflineAccessTokenTypeTok: Label 'urn:shopify:params:oauth:token-type:offline-access-token', Locked = true;
        TokenMigratedTxt: Label 'Migrated Shopify store to an expiring offline access token.', Locked = true;
        TokenMigrationFailedTxt: Label 'Failed to migrate Shopify store to an expiring offline access token. The existing token is kept.', Locked = true;
        TokenRefreshedTxt: Label 'Refreshed the Shopify expiring offline access token.', Locked = true;
        TokenRefreshTransientTxt: Label 'A transient error occurred while refreshing the Shopify access token. The existing token is still valid and will be retried later.', Locked = true;
        TokenRefreshExpiredTxt: Label 'The Shopify refresh token has expired. The store must be reconnected.', Locked = true;

    [NonDebuggable]
    local procedure GetClientId(): Text
    var
        AzureKeyVault: Codeunit "Azure Key Vault";
        EnvironmentInformation: Codeunit "Environment Information";
        ClientId: Text;
    begin
        if not EnvironmentInformation.IsSaaS() then
            Error(NotSupportedOnPremErr);

        if not AzureKeyVault.GetAzureKeyVaultSecret(ShopifyAPIKeyAKVSecretNameLbl, ClientId) then
            Session.LogMessage('0000HCA', MissingAPIKeyTelemetryTxt, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok)
        else
            exit(ClientId);
    end;

    [NonDebuggable]
    local procedure GetClientSecret(): SecretText
    var
        AzureKeyVault: Codeunit "Azure Key Vault";
        EnvironmentInformation: Codeunit "Environment Information";
        ClientSecret: SecretText;
    begin
        if not EnvironmentInformation.IsSaaS() then
            Error(NotSupportedOnPremErr);

        if not AzureKeyVault.GetAzureKeyVaultSecret(ShopifyAPISecretAKVSecretNameLbl, ClientSecret) then
            Session.LogMessage('0000HCB', MissingAPISecretTelemetryTxt, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok)
        else
            exit(ClientSecret);
    end;

    [NonDebuggable]
    internal procedure InstallShopifyApp(InstallToStore: Text; var Shop: Record "Shpfy Shop")
    var
        OAuth2: Codeunit "OAuth2";
        ShopifyAuthentication: Page "Shpfy Authentication";
        State: Integer;
        GrandOptionsTxt: Label 'value', Locked = true;
        FullUrl: Text;
        Url: Text;
        RedirectUrl: Text;
        Store: Text;
        AuthorizationCode: SecretText;
        InstallURLTxt: Label 'https://%1/admin/oauth/authorize?scope=%2&redirect_uri=%3&state=%4&grant_options[]=%5', Comment = '%1 = Store, %2 = Scope, %3 = RedirectUrl, %4 = State, %5 = GrantOptions', Locked = true;
        InstallURLWithClientIdParamTok: Label '%1&client_id=%2', Comment = '%1 = InstallURLTxt, %2 = ClientId', Locked = true;
        NotMatchingStateErr: Label 'The state parameter value does not match.';
        StoreMismatchLbl: Label 'The store URL returned from Shopify differs from the URL you entered. You can find your store''s internal URL in Shopify Admin under Domains settings. Do you want to update the store URL to match?';
    begin
        OAuth2.GetDefaultRedirectURL(RedirectUrl);
        State := Random(999);
        Url := StrSubstNo(InstallURLTxt, InstallToStore, GetScope(), RedirectUrl, State, GrandOptionsTxt);
        FullUrl := StrSubstNo(InstallURLWithClientIdParamTok, Url, GetClientId());
        ShopifyAuthentication.SetOAuth2Properties(FullUrl);
        Commit();
        ShopifyAuthentication.RunModal();
        Store := ShopifyAuthentication.Store();

        if Store <> InstallToStore then
            if Confirm(StoreMismatchLbl) then
                Shop.SetStoreName(Store)
            else
                Error('');

        AuthorizationCode := ShopifyAuthentication.GetAuthorizationCode();
        if AuthorizationCode.IsEmpty() then
            if ShopifyAuthentication.GetAuthError() <> '' then
                Error(ShopifyAuthentication.GetAuthError())
            else
                Error(NoCallbackErr);
        if State <> ShopifyAuthentication.State() then
            Error(NotMatchingStateErr);
        GetToken(Store, AuthorizationCode);
    end;

    [NonDebuggable]
    local procedure GetToken(Store: Text; AuthorizationCode: SecretText)
    var
        RequestBody: JsonObject;
        Credentials: Dictionary of [Text, SecretText];
        ResponseBody: Text;
        StatusCode: Integer;
    begin
        RequestBody.Add('client_id', GetClientId());
        RequestBody.Add('client_secret', '');
        RequestBody.Add('code', '');
        RequestBody.Add('expiring', 1);
        Credentials.Add('$.client_secret', GetClientSecret());
        Credentials.Add('$.code', AuthorizationCode);

        StatusCode := ExecuteTokenRequest(Store, RequestBody, Credentials, ResponseBody);
        if not IsSuccessStatusCode(StatusCode) then
            exit;
        if not ResponseHasAccessToken(ResponseBody) then
            exit;

        SaveInstalledToken(Store, ResponseBody);
    end;

    [NonDebuggable]
    local procedure ExecuteTokenRequest(Store: Text; RequestBody: JsonObject; Credentials: Dictionary of [Text, SecretText]; var ResponseBody: Text): Integer
    var
        SecretBody: SecretText;
        Url: Text;
        HttpClient: HttpClient;
        RequestHeaders: HttpHeaders;
        RequestHttpContent: HttpContent;
        HttpResponseMessage: HttpResponseMessage;
        AccessTokenURLTxt: Label 'https://%1/admin/oauth/access_token', Comment = '%1 = Store', Locked = true;
        HttpRequestBlockedErrorInfo: ErrorInfo;
    begin
        RequestBody.WriteWithSecretsTo(Credentials, SecretBody);

        Url := StrSubstNo(AccessTokenURLTxt, Store);

        RequestHttpContent.WriteFrom(SecretBody);
        RequestHttpContent.GetHeaders(RequestHeaders);
        RequestHeaders.Clear();
        RequestHeaders.Add('Content-Type', 'application/json');

        if not HttpClient.Post(Url, RequestHttpContent, HttpResponseMessage) then
            if HttpResponseMessage.IsBlockedByEnvironment() then begin
                HttpRequestBlockedErrorInfo.DataClassification := HttpRequestBlockedErrorInfo.DataClassification::SystemMetadata;
                HttpRequestBlockedErrorInfo.ErrorType := HttpRequestBlockedErrorInfo.ErrorType::Client;
                HttpRequestBlockedErrorInfo.Verbosity := HttpRequestBlockedErrorInfo.Verbosity::Error;
                HttpRequestBlockedErrorInfo.Message := HttpRequestBlockedErr;
                HttpRequestBlockedErrorInfo.AddAction(EnableHttpRequestActionLbl, Codeunit::"Shpfy Authentication Mgt.", 'EnableHttpRequestForShopifyConnector');
                Error(HttpRequestBlockedErrorInfo);
            end else
                exit(0);

        Clear(ResponseBody);
        HttpResponseMessage.Content().ReadAs(ResponseBody);
        exit(HttpResponseMessage.HttpStatusCode());
    end;

    local procedure SaveInstalledToken(Store: Text; ResponseBody: Text)
    var
        RegisteredStoreNew: Record "Shpfy Registered Store New";
    begin
        Store := Store.ToLower();
        if not RegisteredStoreNew.Get(Store) then begin
            RegisteredStoreNew.Init();
            RegisteredStoreNew.Store := CopyStr(Store, 1, MaxStrLen(RegisteredStoreNew.Store));
            RegisteredStoreNew.Insert();
        end;
        RegisteredStoreNew."Requested Scope" := GetScope();
        RegisteredStoreNew.Modify();
        SaveTokenResponse(RegisteredStoreNew, ResponseBody);
    end;

    [NonDebuggable]
    local procedure SaveTokenResponse(var RegisteredStoreNew: Record "Shpfy Registered Store New"; ResponseBody: Text)
    var
        JsonHelper: Codeunit "Shpfy Json Helper";
        JObject: JsonObject;
        JToken: JsonToken;
        AccessToken: SecretText;
        RefreshToken: SecretText;
        AccessTokenText: Text;
        RefreshTokenText: Text;
        ActualScope: Text;
        ExpiresInSeconds: BigInteger;
        RefreshExpiresInSeconds: BigInteger;
    begin
        if not JObject.ReadFrom(ResponseBody) then
            exit;
        JToken := JObject.AsToken();

        AccessTokenText := JsonHelper.GetValueAsText(JToken, 'access_token');
        if AccessTokenText = '' then
            exit;

        ActualScope := JsonHelper.GetValueAsText(JToken, 'scope');
        if ActualScope <> '' then
            RegisteredStoreNew."Actual Scope" := CopyStr(ActualScope, 1, MaxStrLen(RegisteredStoreNew."Actual Scope"));

        ExpiresInSeconds := JsonHelper.GetValueAsBigInteger(JToken, 'expires_in');
        if ExpiresInSeconds > 0 then
            RegisteredStoreNew."Token Expires At" := AddSeconds(CurrentDateTime(), ExpiresInSeconds)
        else
            RegisteredStoreNew."Token Expires At" := 0DT;

        RefreshExpiresInSeconds := JsonHelper.GetValueAsBigInteger(JToken, 'refresh_token_expires_in');
        if RefreshExpiresInSeconds > 0 then
            RegisteredStoreNew."Refresh Token Expires At" := AddSeconds(CurrentDateTime(), RefreshExpiresInSeconds)
        else
            RegisteredStoreNew."Refresh Token Expires At" := 0DT;

        RegisteredStoreNew.Modify();

        AccessToken := AccessTokenText;
        RegisteredStoreNew.SetAccessToken(AccessToken);

        RefreshTokenText := JsonHelper.GetValueAsText(JToken, 'refresh_token');
        if RefreshTokenText <> '' then begin
            RefreshToken := RefreshTokenText;
            RegisteredStoreNew.SetRefreshToken(RefreshToken);
        end;
    end;

    /// <summary>
    /// Ensures the store has a valid, non-expired offline access token before it is used.
    /// Legacy non-expiring tokens are migrated to expiring tokens on first use, and expiring
    /// tokens are refreshed when they are close to expiry. Refresh/migration is serialized
    /// across sessions and companies via a table lock to respect Shopify's single
    /// refreshable token per app and store.
    /// </summary>
    /// <param name="Store">The store URL.</param>
    internal procedure EnsureValidAccessToken(Store: Text)
    var
        RegisteredStoreNew: Record "Shpfy Registered Store New";
    begin
        Store := Store.ToLower();
        if not RegisteredStoreNew.Get(Store) then
            exit;

        if RegisteredStoreNew.HasRefreshToken() and not TokenNeedsRefresh(RegisteredStoreNew) then
            exit;

        RegisteredStoreNew.LockTable();
        if not RegisteredStoreNew.Get(Store) then
            exit;

        if RegisteredStoreNew.HasRefreshToken() then begin
            if TokenNeedsRefresh(RegisteredStoreNew) then
                RefreshAccessToken(Store, RegisteredStoreNew);
        end else
            if not RegisteredStoreNew.GetAccessToken().IsEmpty() then
                MigrateToExpiringToken(Store, RegisteredStoreNew);

        Commit();
    end;

    /// <summary>
    /// Forces a token refresh (or migration) regardless of the remaining lifetime. Used when an
    /// API call unexpectedly returns 401, indicating the current access token is no longer valid.
    /// </summary>
    /// <param name="Store">The store URL.</param>
    internal procedure ForceTokenRefresh(Store: Text)
    var
        RegisteredStoreNew: Record "Shpfy Registered Store New";
    begin
        Store := Store.ToLower();
        if not RegisteredStoreNew.Get(Store) then
            exit;

        RegisteredStoreNew.LockTable();
        if not RegisteredStoreNew.Get(Store) then
            exit;

        if RegisteredStoreNew.HasRefreshToken() then
            RefreshAccessToken(Store, RegisteredStoreNew)
        else
            if not RegisteredStoreNew.GetAccessToken().IsEmpty() then
                MigrateToExpiringToken(Store, RegisteredStoreNew);

        Commit();
    end;

    [NonDebuggable]
    local procedure MigrateToExpiringToken(Store: Text; var RegisteredStoreNew: Record "Shpfy Registered Store New")
    var
        RequestBody: JsonObject;
        Credentials: Dictionary of [Text, SecretText];
        ResponseBody: Text;
        StatusCode: Integer;
    begin
        RequestBody.Add('client_id', GetClientId());
        RequestBody.Add('client_secret', '');
        RequestBody.Add('grant_type', TokenExchangeGrantTypeTok);
        RequestBody.Add('subject_token', '');
        RequestBody.Add('subject_token_type', OfflineAccessTokenTypeTok);
        RequestBody.Add('requested_token_type', OfflineAccessTokenTypeTok);
        RequestBody.Add('expiring', 1);
        Credentials.Add('$.client_secret', GetClientSecret());
        Credentials.Add('$.subject_token', RegisteredStoreNew.GetAccessToken());

        StatusCode := ExecuteTokenRequest(Store, RequestBody, Credentials, ResponseBody);

        // Migration is best-effort: the non-expiring token still works until January 1, 2027,
        // so a transient failure must not break the connector. On success the old token is revoked.
        if IsSuccessStatusCode(StatusCode) and ResponseHasAccessToken(ResponseBody) then begin
            SaveTokenResponse(RegisteredStoreNew, ResponseBody);
            LogTokenTelemetry('0000QK1', TokenMigratedTxt);
        end else
            LogTokenTelemetry('0000QK2', TokenMigrationFailedTxt);
    end;

    [NonDebuggable]
    local procedure RefreshAccessToken(Store: Text; var RegisteredStoreNew: Record "Shpfy Registered Store New")
    var
        RequestBody: JsonObject;
        Credentials: Dictionary of [Text, SecretText];
        ResponseBody: Text;
        StatusCode: Integer;
        Attempt: Integer;
        MaxAttempts: Integer;
    begin
        if RefreshTokenExpired(RegisteredStoreNew) then begin
            LogTokenTelemetry('0000QK3', TokenRefreshExpiredTxt);
            Error(RefreshTokenExpiredErr, Store);
        end;

        MaxAttempts := 3;
        for Attempt := 1 to MaxAttempts do begin
            Clear(RequestBody);
            Clear(Credentials);
            RequestBody.Add('client_id', GetClientId());
            RequestBody.Add('client_secret', '');
            RequestBody.Add('grant_type', RefreshTokenGrantTypeTok);
            RequestBody.Add('refresh_token', '');
            Credentials.Add('$.client_secret', GetClientSecret());
            // Retry uses the SAME refresh token: Shopify returns the same response for up to 1 hour.
            Credentials.Add('$.refresh_token', RegisteredStoreNew.GetRefreshToken());

            StatusCode := ExecuteTokenRequest(Store, RequestBody, Credentials, ResponseBody);

            if IsSuccessStatusCode(StatusCode) and ResponseHasAccessToken(ResponseBody) then begin
                SaveTokenResponse(RegisteredStoreNew, ResponseBody);
                LogTokenTelemetry('0000QK4', TokenRefreshedTxt);
                exit;
            end;

            // A 401 with an inactive refresh token is terminal: the merchant must reconnect.
            if StatusCode = 401 then begin
                LogTokenTelemetry('0000QK3', TokenRefreshExpiredTxt);
                Error(RefreshTokenExpiredErr, Store);
            end;

            Sleep(1000 * Attempt);
        end;

        // Transient failures exhausted. If the current access token is already expired the store
        // cannot make calls, so surface the reconnect error; otherwise keep the still-valid token.
        if TokenExpired(RegisteredStoreNew) then
            Error(RefreshTokenExpiredErr, Store);
        LogTokenTelemetry('0000QK5', TokenRefreshTransientTxt);
    end;

    local procedure TokenNeedsRefresh(RegisteredStoreNew: Record "Shpfy Registered Store New"): Boolean
    begin
        // A non-expiring token (no expiry recorded) never needs refreshing.
        if RegisteredStoreNew."Token Expires At" = 0DT then
            exit(false);
        exit(CurrentDateTime() + GetRefreshBufferMs() >= RegisteredStoreNew."Token Expires At");
    end;

    local procedure TokenExpired(RegisteredStoreNew: Record "Shpfy Registered Store New"): Boolean
    begin
        exit((RegisteredStoreNew."Token Expires At" <> 0DT) and (CurrentDateTime() >= RegisteredStoreNew."Token Expires At"));
    end;

    local procedure RefreshTokenExpired(RegisteredStoreNew: Record "Shpfy Registered Store New"): Boolean
    begin
        exit((RegisteredStoreNew."Refresh Token Expires At" <> 0DT) and (CurrentDateTime() >= RegisteredStoreNew."Refresh Token Expires At"));
    end;

    local procedure GetRefreshBufferMs(): Duration
    begin
        exit(5 * 60 * 1000); // Refresh 5 minutes before the access token expires.
    end;

    local procedure AddSeconds(StartDateTime: DateTime; Seconds: BigInteger): DateTime
    var
        Lifetime: Duration;
    begin
        Lifetime := Seconds * 1000;
        exit(StartDateTime + Lifetime);
    end;

    local procedure IsSuccessStatusCode(StatusCode: Integer): Boolean
    begin
        exit((StatusCode >= 200) and (StatusCode < 300));
    end;

    local procedure ResponseHasAccessToken(ResponseBody: Text): Boolean
    var
        JsonHelper: Codeunit "Shpfy Json Helper";
        JObject: JsonObject;
    begin
        if not JObject.ReadFrom(ResponseBody) then
            exit(false);
        exit(JsonHelper.GetValueAsText(JObject.AsToken(), 'access_token') <> '');
    end;

    local procedure LogTokenTelemetry(EventId: Text; Message: Text)
    begin
        Session.LogMessage(EventId, Message, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
    end;

    [NonDebuggable]
    internal procedure AccessTokenExist(Store: Text): Boolean
    var
        RegisteredStoreNew: Record "Shpfy Registered Store New";
    begin
        if RegisteredStoreNew.Get(Store) then
            if RegisteredStoreNew."Requested Scope" = GetScope() then
                exit(not RegisteredStoreNew.GetAccessToken().IsEmpty());
    end;

    /// <summary>
    /// Returns whether the store uses an expiring offline token whose refresh token has expired,
    /// meaning the merchant must reconnect the store before the connector can be used again.
    /// </summary>
    /// <param name="Store">The store URL.</param>
    internal procedure IsRefreshTokenExpired(Store: Text): Boolean
    var
        RegisteredStoreNew: Record "Shpfy Registered Store New";
    begin
        Store := Store.ToLower();
        if not RegisteredStoreNew.Get(Store) then
            exit(false);
        if not RegisteredStoreNew.HasRefreshToken() then
            exit(false);
        exit(RefreshTokenExpired(RegisteredStoreNew));
    end;

    internal procedure ReconnectFromNotification(ReconnectNotification: Notification)
    var
        Shop: Record "Shpfy Shop";
        ShopCode: Code[20];
    begin
        if Evaluate(ShopCode, ReconnectNotification.GetData('ShopCode')) then
            if Shop.Get(ShopCode) then begin
                Shop.RequestAccessToken();
                Shop.GetShopSettings();
                Shop.Modify();
            end;
    end;

    internal procedure AssertValidShopUrl(ShopUrl: Text)
    var
        URI: Codeunit Uri;
        PatternLbl: Label '^(https)\:\/\/[a-zA-Z0-9][a-zA-Z0-9\-]*\.myshopify\.com[\/]*$', Locked = true;
    begin
        if not URI.IsValidURIPattern(ShopUrl, PatternLbl) then
            Error(InvalidShopUrlErr);
    end;

    procedure IsValidHostName(Hostname: Text): Boolean
    var
        URI: Codeunit Uri;
        PatternLbl: Label '^[a-zA-Z0-9][a-zA-Z0-9\-]*\.myshopify\.com$', Locked = true;
    begin
        exit(URI.IsValidURIPattern(Hostname, PatternLbl));
    end;

    procedure CorrectShopUrl(var ShopUrl: Text[250])
    begin
        if not ShopUrl.ToLower().StartsWith('https://') then
            ShopUrl := CopyStr('https://' + ShopUrl, 1, MaxStrLen(ShopUrl));

        if ShopUrl.ToLower().StartsWith('https://admin.shopify.com/store/') then begin
            ShopUrl := CopyStr(ShopUrl.TrimEnd('?'), 1, MaxStrLen(ShopUrl));
            ShopUrl := CopyStr('https://' + ShopUrl.Replace('https://admin.shopify.com/store/', '').Split('/').Get(1) + '.myshopify.com', 1, MaxStrLen(ShopUrl));
        end;
    end;

    internal procedure EnableHttpRequestForShopifyConnector(ErrorInfo: ErrorInfo)
    var
        ExtensionManagement: Codeunit "Extension Management";
        CallerModuleInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(CallerModuleInfo);
        ExtensionManagement.ConfigureExtensionHttpClientRequestsAllowance(CallerModuleInfo.PackageId(), true);
    end;

    internal procedure CheckScopeChange(Shop: Record "Shpfy Shop"): Boolean
    var
        RegisteredStoreNew: Record "Shpfy Registered Store New";
        ActualScopes: List of [Text];
        RequestedScopes: List of [Text];
        Scope: Text;
    begin
        if not RegisteredStoreNew.Get(Shop.GetStoreName()) then
            exit(false);

        ActualScopes := RegisteredStoreNew."Actual Scope".Split(',');
        RequestedScopes := GetScope().Split(',');

        if ActualScopes.Count() <> RequestedScopes.Count() then
            exit(true);

        foreach Scope in RequestedScopes do
            if not ActualScopes.Contains(Scope) then
                exit(true);

        exit(false);
    end;

    internal procedure GetScope(): Text[1024]
    begin
        exit(ScopeTxt);
    end;
}
