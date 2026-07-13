namespace System.AI;

using System.Azure.KeyVault;
using System.Security.Authentication;

codeunit 2004 "Machine Learning KeyVaultMgmt."
{
    SingleInstance = true;

    trigger OnRun()
    begin
    end;

    var
        LimitTypeOption: Option Year,Month,Day,Hour;
        MLKVTok: Label 'Azure Machine Learning', Locked = true;
        MissingFirstPartyAppIdOrCertificateTelemetryTxt: Label 'The first-party app id or certificate have not been initialized.', Locked = true;
        MissingKVNameTelemetryTxt: Label '%1 could not be found in in KV.', Locked = true;
        OAuthAquireTokenErr: Label 'Failed to get OAuth from AcquireTokensWithCertificate', Locked = true;
        OAuthEmtpyAccessTokenErr: Label 'Access Token from AcquireTokensWithCertificate is empty.', Locked = true;
        FirstPartyAppIdKVNameLbl: Label 'AzureML-Client', Locked = true;
        FirstPartyAppCertificateKVNameLbl: Label 'AzureML-CertKVName', Locked = true;
        FirstPartyAppOAuthUrlKVNameLbl: Label 'AzureML-Authority', Locked = true;
        FirstPartyAppScopeLblLbl: Label 'https://ml.azure.com/.default', Locked = true;
        MLStudioAppUrlKVNameLbl: Label 'AzureML-Url', Locked = true;


    [NonDebuggable]
    [Scope('OnPrem')]
    procedure GetMachineLearningCredentials(SecretName: Text; var ApiUri: Text[250]; var ApiKey: SecretText; var LimitType: Option; var Limit: Decimal)
    var
        AzureKeyVault: Codeunit "Azure Key Vault";
        SecretObject: JsonObject;
        ApiKeys: JsonArray;
        ApiUris: JsonArray;
        RandomIndex: Integer;
        SecretValue: Text;
        LimitTxt: Text;
        LimitTypeTxt: Text;
        Value: Text;
    begin
        // If MLStudioAppUrlKVNameLbl is set in KV, use new function to get access token.
        if AzureKeyVault.GetAzureKeyVaultSecret(MLStudioAppUrlKVNameLbl, Value) then begin
            GetMachineLearningCredentials(ApiUri, ApiKey, LimitType, Limit);
            exit;
        end;

        if not AzureKeyVault.GetAzureKeyVaultSecret(SecretName, SecretValue) then
            exit;

        // check if the secret is a properly formatted JSON object
        if not SecretObject.ReadFrom(SecretValue) then
            exit;

        GetAsText(SecretObject, 'Limit', LimitTxt);
        if LimitTxt <> '' then
            Evaluate(Limit, LimitTxt, 9);

        GetAsText(SecretObject, 'LimitType', LimitTxt);
        if LimitTypeTxt = '' then
            LimitTypeTxt := 'Month';

        LimitType := GetLimitTypeOptionFromText(LimitTypeTxt);

        if not GetAsArray(SecretObject, 'ApiKeys', ApiKeys) then
            exit;

        if not GetAsArray(SecretObject, 'ApiUris', ApiUris) then
            exit;

        if (ApiKeys.Count() = 0) or (ApiUris.Count() = 0) then
            exit;

        RandomIndex := Random(ApiKeys.Count()) - 1;
        GetAsSecretText(ApiKeys, RandomIndex, ApiKey);
        GetAsText(ApiUris, RandomIndex, ApiUri);
    end;

    [NonDebuggable]
    [Scope('OnPrem')]
    procedure GetMachineLearningCredentials(var ApiUrl: Text[250]; var ApiAccessToken: SecretText; var LimitType: Option; var Limit: Decimal): Boolean
    var
        OAuth2: Codeunit OAuth2;
        Cert: SecretText;
        AppId, RedirectUrl, AuthUrl, IdToken : Text;
        Scopes: List of [Text];
    begin
        if not GetAPIUrlAndLimit(MLStudioAppUrlKVNameLbl, ApiUrl, LimitType, Limit) then
            exit;

        if not GetAppId(FirstPartyAppIdKVNameLbl, AppId) then
            exit;

        if not GetCertificate(FirstPartyAppCertificateKVNameLbl, Cert) then
            exit;

        if not GetAuthUrl(FirstPartyAppOAuthUrlKVNameLbl, AuthUrl) then
            exit;

        Scopes.Add(FirstPartyAppScopeLblLbl);
        if not OAuth2.AcquireTokensWithCertificate(AppId, Cert, RedirectUrl, AuthUrl, Scopes, ApiAccessToken, IdToken) then begin
            Session.LogMessage('0000N14', OAuthAquireTokenErr, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', MLKVTok);
            exit(false);
        end;

        if ApiAccessToken.IsEmpty() then begin
            Session.LogMessage('0000N15', OAuthEmtpyAccessTokenErr, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', MLKVTok);
            exit(false);
        end;

        exit(true);
    end;

    [NonDebuggable]
    local procedure GetAPIUrlAndLimit(ApiUrlKVName: Text; var AppUrl: Text[250]; var LimitType: Option; var Limit: Decimal): Boolean;
    var
        AzureKeyVault: Codeunit "Azure Key Vault";
        SecretObject: JsonObject;
        ApiUrls: JsonArray;
        SecretValue: Text;
        LimitTxt, LocalAppUrl : Text;
        LimitTypeTxt: Text;
        RandomIndex: Integer;
    begin
        if not AzureKeyVault.GetAzureKeyVaultSecret(ApiUrlKVName, SecretValue) then
            Session.LogMessage('0000N16', StrSubstNo(MissingKVNameTelemetryTxt, ApiUrlKVName), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', MLKVTok);

        // check if the secret is a properly formatted JSON object
        if not SecretObject.ReadFrom(SecretValue) then
            exit;

        GetAsText(SecretObject, 'Limit', LimitTxt);
        if LimitTxt <> '' then
            Evaluate(Limit, LimitTxt, 9);

        GetAsText(SecretObject, 'LimitType', LimitTxt);
        if LimitTypeTxt = '' then
            LimitTypeTxt := 'Month';

        LimitType := GetLimitTypeOptionFromText(LimitTypeTxt);

        if not GetAsArray(SecretObject, 'ApiUris', ApiUrls) then
            exit;

        if ApiUrls.Count() = 0 then
            exit;

        RandomIndex := Random(ApiUrls.Count()) - 1;
        GetAsText(ApiUrls, RandomIndex, LocalAppUrl);
        AppUrl := CopyStr(LocalAppUrl, 1, MaxStrLen(AppUrl));
        exit(true);
    end;


    [NonDebuggable]
    local procedure GetAppId(AppIdKVName: Text; var AppId: Text): Boolean;
    var
        AzureKeyVault: Codeunit "Azure Key Vault";
    begin
        if not AzureKeyVault.GetAzureKeyVaultSecret(AppIdKVName, AppId) then begin
            Session.LogMessage('0000N17', MissingFirstPartyAppIdOrCertificateTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', MLKVTok);
            exit(false);
        end;

        exit(true);
    end;

    [NonDebuggable]
    local procedure GetAuthUrl(AppOAuthKVName: Text; var OAuthUrl: Text): Boolean;
    var
        AzureKeyVault: Codeunit "Azure Key Vault";
    begin
        if not AzureKeyVault.GetAzureKeyVaultSecret(AppOAuthKVName, OAuthUrl) then begin
            Session.LogMessage('0000N18', StrSubstNo(MissingKVNameTelemetryTxt, AppOAuthKVName), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', MLKVTok);
            exit(false);
        end;

        exit(true);
    end;

    [NonDebuggable]
    local procedure GetCertificate(CertificateKVName: Text; var Certificate: SecretText): Boolean
    var
        AzureKeyVault: Codeunit "Azure Key Vault";
        CertificateName: Text;
    begin
        if not AzureKeyVault.GetAzureKeyVaultSecret(CertificateKVName, CertificateName) then begin
            Session.LogMessage('0000N1A', MissingFirstPartyappIdOrCertificateTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', MLKVTok);
            exit(false);
        end;

        if not AzureKeyVault.GetAzureKeyVaultCertificate(CertificateName, Certificate) then begin
            Session.LogMessage('0000N1B', MissingFirstPartyappIdOrCertificateTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', MLKVTok);
            exit(false);
        end;
        exit(true);
    end;

    [NonDebuggable]
    local procedure GetAsText(JArray: JsonArray; Index: Integer; var Result: Text): Boolean
    var
        JToken: JsonToken;
    begin
        if not JArray.Get(Index, JToken) then
            exit(false);

        exit(GetAsText(JToken, Result));
    end;

    [NonDebuggable]
    local procedure GetAsSecretText(JArray: JsonArray; Index: Integer; var SecretResult: SecretText): Boolean
    var
        Result: Text;
    begin
        if GetAsText(Jarray, Index, Result) then begin
            SecretResult := Result;
            exit(true);
        end;

        exit(false);
    end;

    [NonDebuggable]
    local procedure GetAsText(JObject: JsonObject; PropertyKey: Text; var Result: Text): Boolean
    var
        JToken: JsonToken;
    begin
        if not JObject.Get(PropertyKey, JToken) then
            exit(false);

        exit(GetAsText(JToken, Result));
    end;

    [NonDebuggable]
    local procedure GetAsText(JToken: JsonToken; var Result: Text): Boolean
    var
        JValue: JsonValue;
    begin
        if not JToken.IsValue() then
            exit(false);

        JValue := JToken.AsValue();
        if JValue.IsUndefined() or JValue.IsNull() then
            exit(false);

        Result := JValue.AsText();
        exit(true);
    end;

    [NonDebuggable]
    local procedure GetAsArray(JObject: JsonObject; PropertyKey: Text; var Result: JsonArray): Boolean
    var
        JToken: JsonToken;
    begin
        if not JObject.Get(PropertyKey, JToken) then
            exit(false);

        if not JToken.IsArray() then
            exit(false);

        Result := JToken.AsArray();
        exit(true);
    end;

    procedure GetLimitTypeOptionFromText(LimitTypeTxt: Text): Integer
    begin
        case LimitTypeTxt of
            'Year':
                exit(LimitTypeOption::Year);
            'Month':
                exit(LimitTypeOption::Month);
            'Day':
                exit(LimitTypeOption::Day);
            'Hour':
                exit(LimitTypeOption::Hour);
        end;
    end;
}
