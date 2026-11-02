namespace Microsoft.FabricExport;

using System.Azure.Identity;
using System.Security.Authentication;
using System.Security.Encryption;

codeunit 48524 "Fabric Platform Credential Mgt"
{
    Access = Internal;

    var
        ClientIdRequiredErr: Label 'Client ID must be filled in before acquiring a Fabric API token.';
        TenantIdRequiredErr: Label 'Microsoft Entra tenant ID could not be determined.';
        FabricApiTokenErr: Label 'Failed to acquire a Microsoft Fabric API token. Sign in again and verify that admin consent was granted.';
        FabricApiTokenInteractiveErr: Label 'Failed to acquire the Fabric API token interactively. Verify the app registration in Microsoft Entra ID and that redirect URL %1 is registered.', Comment = '%1 = redirect URL';
        EncryptionNotEnabledErr: Label 'The Client Secret cannot be stored because data encryption is not enabled for this environment.';
        OpenDataEncryptionMgtLbl: Label 'Activate encryption';
        OAuthAuthorityUrlTok: Label 'https://login.microsoftonline.com/%1/oauth2/v2.0/authorize', Comment = '%1 = tenant ID', Locked = true;

    internal procedure IsCustomAppEnabled(): Boolean
    begin
        exit(IsolatedStorage.Contains('FabricPlat.UseCustomApp', DataScope::Module));
    end;

    internal procedure SetCustomAppEnabled(Enabled: Boolean)
    begin
        if Enabled then
            IsolatedStorage.Set('FabricPlat.UseCustomApp', 'true', DataScope::Module)
        else begin
            DeleteStoredValue('FabricPlat.UseCustomApp');
            ClearClientSecret('SwitchTo1P');
        end;
        ClearTokenCache();
    end;

    internal procedure ClearClientSecret(ChangeTrigger: Text)
    var
        FabricPlatformTelemetry: Codeunit "Fabric Platform Telemetry";
    begin
        if IsolatedStorage.Contains('FabricPlat.ClientSecret', DataScope::Module) then begin
            IsolatedStorage.Delete('FabricPlat.ClientSecret', DataScope::Module);
            FabricPlatformTelemetry.LogCredentialChanged('Deleted', ChangeTrigger, GetCustomClientId());
        end;
        ClearTokenCache();
    end;

    internal procedure ClearEnvironmentCredentials()
    begin
        ClearClientSecret('EnvironmentCleanup');
        DeleteStoredValue('FabricPlat.UseCustomApp');
        DeleteStoredValue('FabricPlat.ClientId');
        DeleteStoredValue('FabricPlat.PrincipalId');
        DeleteStoredValue('FabricPlat.FirstPartyPrincipalId');
        DeleteStoredValue('FabricPlat.OpenMirroringDatabaseName');
        DeleteStoredValue('FabricPlat.LastEnableRequestedAt');
    end;

    local procedure DeleteStoredValue(StorageKey: Text)
    begin
        if IsolatedStorage.Contains(StorageKey, DataScope::Module) then
            IsolatedStorage.Delete(StorageKey, DataScope::Module);
    end;

    internal procedure SetClientId(ClientId: Text)
    begin
        IsolatedStorage.Set('FabricPlat.ClientId', ClientId, DataScope::Module);
    end;

    /// <summary>Returns the client ID entered for the user's own app registration, regardless of the active mode.</summary>
    internal procedure GetCustomClientId(): Text
    var
        Value: Text;
    begin
        if IsolatedStorage.Get('FabricPlat.ClientId', DataScope::Module, Value) then
            exit(Value);
        exit('');
    end;

    internal procedure GetTenantId(): Text
    var
        AzureADTenant: Codeunit "Azure AD Tenant";
    begin
        exit(AzureADTenant.GetAadTenantId());
    end;

    internal procedure SetPrincipalId(PrincipalId: Text)
    begin
        IsolatedStorage.Set(PrincipalIdStorageKey(), PrincipalId, DataScope::Module);
    end;

    internal procedure GetPrincipalId(): Text
    var
        Value: Text;
    begin
        if IsolatedStorage.Get(PrincipalIdStorageKey(), DataScope::Module, Value) then
            exit(Value);
        exit('');
    end;

    // Each app has its own service principal, so the first-party and custom apps keep separate values.
    local procedure PrincipalIdStorageKey(): Text
    begin
        if IsCustomAppEnabled() then
            exit('FabricPlat.PrincipalId');
        exit('FabricPlat.FirstPartyPrincipalId');
    end;

    internal procedure SetOpenMirroringDatabaseName(OpenMirroringDatabaseName: Text)
    begin
        IsolatedStorage.Set('FabricPlat.OpenMirroringDatabaseName', OpenMirroringDatabaseName, DataScope::Module);
    end;

    internal procedure GetOpenMirroringDatabaseName(): Text
    var
        Value: Text;
    begin
        if IsolatedStorage.Get('FabricPlat.OpenMirroringDatabaseName', DataScope::Module, Value) then
            exit(Value);
        exit('');
    end;

    internal procedure SetLastEnableRequestedAt(Value: DateTime)
    begin
        IsolatedStorage.Set('FabricPlat.LastEnableRequestedAt', Format(Value, 0, 9), DataScope::Module);
    end;

    internal procedure GetLastEnableRequestedAt(): DateTime
    var
        Value: Text;
        Result: DateTime;
    begin
        if IsolatedStorage.Get('FabricPlat.LastEnableRequestedAt', DataScope::Module, Value) then
            if Evaluate(Result, Value, 9) then
                exit(Result);
        exit(0DT);
    end;

    [NonDebuggable]
    internal procedure SetClientSecret(ClientSecret: SecretText)
    var
        CryptographyManagement: Codeunit "Cryptography Management";
        FabricPlatformTelemetry: Codeunit "Fabric Platform Telemetry";
        EncryptionNotEnabledErrorInfo: ErrorInfo;
        ReplacingCredential: Boolean;
    begin
        if CryptographyManagement.IsEncryptionEnabled() then begin
            ReplacingCredential := IsolatedStorage.Contains('FabricPlat.ClientSecret', DataScope::Module);
            if ReplacingCredential then
                IsolatedStorage.Delete('FabricPlat.ClientSecret', DataScope::Module);
            IsolatedStorage.SetEncrypted('FabricPlat.ClientSecret', ClientSecret, DataScope::Module);
            if ReplacingCredential then
                FabricPlatformTelemetry.LogCredentialChanged('Replaced', 'SetupPage', GetCustomClientId())
            else
                FabricPlatformTelemetry.LogCredentialChanged('Stored', 'SetupPage', GetCustomClientId());
            exit;
        end;

        EncryptionNotEnabledErrorInfo := ErrorInfo.Create(EncryptionNotEnabledErr);
        EncryptionNotEnabledErrorInfo.PageNo(Page::"Data Encryption Management");
        EncryptionNotEnabledErrorInfo.AddNavigationAction(OpenDataEncryptionMgtLbl);
        Error(EncryptionNotEnabledErrorInfo);
    end;

    [NonDebuggable]
    internal procedure IsClientSecretSet(): Boolean
    begin
        exit(not GetClientSecretSecure().IsEmpty());
    end;

    [NonDebuggable]
    internal procedure GetClientSecret(): SecretText
    begin
        exit(GetClientSecretSecure());
    end;

    procedure ClearTokenCache()
    var
        LookupState: Codeunit "Fabric Platform Lookup State";
    begin
        LookupState.ClearFabricApiToken();
    end;

    /// <summary>
    /// Acquires a delegated Fabric API token via On-Behalf-Of for the first-party app.
    /// </summary>
    [NonDebuggable]
    procedure AcquireFabricApiTokenDelegated(): SecretText
    var
        OAuth2: Codeunit OAuth2;
        LookupState: Codeunit "Fabric Platform Lookup State";
        AccessToken: SecretText;
        RedirectUrl: Text;
        Scopes: List of [Text];
    begin
        // Test-injection seam: unit tests pre-seed a token to bypass the platform flow.
        if LookupState.HasFabricApiToken() then
            exit(LookupState.GetFabricApiToken());

        if IsCustomAppEnabled() then
            exit(AcquireFabricApiTokenWithCustomApp());

        Scopes.Add('https://api.fabric.microsoft.com/Workspace.ReadWrite.All');
        OAuth2.GetDefaultRedirectUrl(RedirectUrl);
        OAuth2.AcquireOnBehalfOfToken(RedirectUrl, Scopes, AccessToken);
        if AccessToken.IsEmpty() then
            Error(FabricApiTokenErr);
        exit(AccessToken);
    end;

    [NonDebuggable]
    local procedure AcquireFabricApiTokenWithCustomApp(): SecretText
    var
        OAuth2: Codeunit OAuth2;
        LookupState: Codeunit "Fabric Platform Lookup State";
        AccessToken: SecretText;
        IdToken: Text;
        Scopes: List of [Text];
        AuthorityTenantId: Text;
        OAuthAuthorityUrl: Text;
        RedirectUrl: Text;
    begin
        if GetCustomClientId() = '' then
            Error(ClientIdRequiredErr);
        AuthorityTenantId := GetTenantId();
        if AuthorityTenantId = '' then
            Error(TenantIdRequiredErr);

        OAuthAuthorityUrl := StrSubstNo(OAuthAuthorityUrlTok, AuthorityTenantId);
        Scopes.Add('https://api.fabric.microsoft.com/.default');
        OAuth2.GetDefaultRedirectUrl(RedirectUrl);

        OAuth2.AcquireTokenByAuthorizationCode(
            GetCustomClientId(),
            GetClientSecretSecure(),
            OAuthAuthorityUrl,
            RedirectUrl,
            Scopes,
            "Prompt Interaction"::"Select Account",
            AccessToken,
            IdToken);
        if AccessToken.IsEmpty() then
            Error(FabricApiTokenInteractiveErr, RedirectUrl);

        // Delegated tokens from AL OAuth2 do not expose expires_in; use a conservative 1-hour TTL.
        LookupState.SetFabricApiToken(AccessToken, 3600);
        exit(AccessToken);
    end;

    [NonDebuggable]
    local procedure GetClientSecretSecure(): SecretText
    var
        Value: SecretText;
        EmptySecret: SecretText;
    begin
        if not IsolatedStorage.Contains('FabricPlat.ClientSecret', DataScope::Module) then
            exit(EmptySecret);
#pragma warning disable LC0043
        if IsolatedStorage.Get('FabricPlat.ClientSecret', DataScope::Module, Value) then
            exit(Value);
#pragma warning restore LC0043
        exit(EmptySecret);
    end;
}
