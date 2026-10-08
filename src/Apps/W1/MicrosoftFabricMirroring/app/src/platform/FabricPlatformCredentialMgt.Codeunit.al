namespace Microsoft.FabricExport;

using System.Azure.Identity;
using System.Security.Authentication;
#if not CLEAN29
using System.Security.Encryption;
#endif

codeunit 48524 "Fabric Platform Credential Mgt"
{
    Access = Internal;

    var
        FabricMirroringAppIdTok: Label 'dcc80069-ba40-4ad9-ba8c-60001cea3497', Locked = true;
        AdminConsentUrlTok: Label 'https://login.microsoftonline.com/%1/adminconsent', Comment = '%1 = tenant ID', Locked = true;
        ClientIdRequiredErr: Label 'Client ID must be filled in before acquiring a Fabric API token.';
        TenantIdRequiredErr: Label 'Microsoft Entra tenant ID could not be determined.';
        AdminConsentFailedErr: Label 'Admin consent was not granted. %1', Comment = '%1 = error details returned by Microsoft Entra ID';
        FabricApiTokenErr: Label 'Failed to acquire a Microsoft Fabric API token. Sign in again and verify that admin consent was granted.';
        GraphApiTokenErr: Label 'Failed to acquire a Microsoft Graph token. Sign in again and verify that admin consent was granted.';
#if not CLEAN29
        FabricApiTokenInteractiveErr: Label 'Failed to acquire the Fabric API token interactively. Verify the app registration and that redirect URL %1 is registered.', Comment = '%1 = redirect URL';
        EncryptionNotEnabledErr: Label 'The Client Secret cannot be stored because data encryption is not enabled for this environment.';
        OpenDataEncryptionMgtLbl: Label 'Activate Encryption';
        OAuthAuthorityUrlTok: Label 'https://login.microsoftonline.com/%1/oauth2/v2.0/authorize', Comment = '%1 = tenant ID', Locked = true;
#endif

#if not CLEAN29
    [Obsolete('Third-party authentication with a custom app registration is replaced by the Microsoft first-party application.', '29.0')]
    internal procedure IsCustomAppEnabled(): Boolean
    begin
        exit(IsolatedStorage.Contains('FabricPlat.UseCustomApp', DataScope::Module));
    end;

    [Obsolete('Third-party authentication with a custom app registration is replaced by the Microsoft first-party application.', '29.0')]
    internal procedure SetCustomAppEnabled(Enabled: Boolean)
    begin
        if Enabled then
            IsolatedStorage.Set('FabricPlat.UseCustomApp', 'true', DataScope::Module)
        else
            if IsolatedStorage.Contains('FabricPlat.UseCustomApp', DataScope::Module) then
                IsolatedStorage.Delete('FabricPlat.UseCustomApp', DataScope::Module);
    end;

    [Obsolete('Third-party authentication with a custom app registration is replaced by the Microsoft first-party application.', '29.0')]
    internal procedure SetClientId(ClientId: Text)
    begin
        IsolatedStorage.Set('FabricPlat.ClientId', ClientId, DataScope::Module);
    end;

    /// <summary>Returns the client ID entered for the user's own app registration, regardless of the active mode.</summary>
    [Obsolete('Third-party authentication with a custom app registration is replaced by the Microsoft first-party application.', '29.0')]
    internal procedure GetCustomClientId(): Text
    var
        Value: Text;
    begin
        if IsolatedStorage.Get('FabricPlat.ClientId', DataScope::Module, Value) then
            exit(Value);
        exit('');
    end;
#endif

    /// <summary>Returns the client ID of the active app: the Microsoft first-party app unless a custom app registration is enabled.</summary>
    internal procedure GetClientId(): Text
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if IsCustomAppEnabled() then
            exit(GetCustomClientId());
#pragma warning restore AL0432
#endif
        exit(FabricMirroringAppIdTok);
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
#if not CLEAN29
#pragma warning disable AL0432
        if IsCustomAppEnabled() then
            exit('FabricPlat.PrincipalId');
#pragma warning restore AL0432
#endif
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

#if not CLEAN29
    [Obsolete('Third-party authentication with a custom app registration is replaced by the Microsoft first-party application.', '29.0')]
    [NonDebuggable]
    internal procedure SetClientSecret(ClientSecret: SecretText)
    var
        CryptographyManagement: Codeunit "Cryptography Management";
        EncryptionNotEnabledErrorInfo: ErrorInfo;
    begin
        if IsolatedStorage.Contains('FabricPlat.ClientSecret', DataScope::Module) then
            IsolatedStorage.Delete('FabricPlat.ClientSecret', DataScope::Module);
        if CryptographyManagement.IsEncryptionEnabled() then begin
            IsolatedStorage.SetEncrypted('FabricPlat.ClientSecret', ClientSecret, DataScope::Module);
            exit;
        end;

        EncryptionNotEnabledErrorInfo := ErrorInfo.Create(EncryptionNotEnabledErr);
        EncryptionNotEnabledErrorInfo.PageNo(Page::"Data Encryption Management");
        EncryptionNotEnabledErrorInfo.AddNavigationAction(OpenDataEncryptionMgtLbl);
        Error(EncryptionNotEnabledErrorInfo);
    end;

    [Obsolete('Third-party authentication with a custom app registration is replaced by the Microsoft first-party application.', '29.0')]
    [NonDebuggable]
    internal procedure IsClientSecretSet(): Boolean
    begin
        exit(not GetClientSecretSecure().IsEmpty());
    end;

    [Obsolete('Third-party authentication with a custom app registration is replaced by the Microsoft first-party application.', '29.0')]
    [NonDebuggable]
    internal procedure GetClientSecret(): SecretText
    begin
        exit(GetClientSecretSecure());
    end;
#endif

    procedure ClearTokenCache()
    var
        LookupState: Codeunit "Fabric Platform Lookup State";
    begin
        LookupState.ClearFabricApiToken();
        LookupState.ClearGraphApiToken();
    end;

    /// <summary>
    /// Provisions the first-party app's service principal in the customer's Entra tenant (one-time, secret-free).
    /// </summary>
    procedure RequestAdminConsent()
    var
        OAuth2: Codeunit OAuth2;
        AuthorityTenantId: Text;
        AdminConsentUrl: Text;
        PermissionGrantError: Text;
        HasConsentSucceeded: Boolean;
    begin
        if GetClientId() = '' then
            Error(ClientIdRequiredErr);
        AuthorityTenantId := GetTenantId();
        if AuthorityTenantId = '' then
            Error(TenantIdRequiredErr);

        AdminConsentUrl := StrSubstNo(AdminConsentUrlTok, AuthorityTenantId);
        OAuth2.RequestClientCredentialsAdminPermissions(GetClientId(), AdminConsentUrl, '', HasConsentSucceeded, PermissionGrantError);
        if not HasConsentSucceeded then
            Error(AdminConsentFailedErr, PermissionGrantError);
    end;

    /// <summary>
    /// Acquires a delegated Microsoft Graph token via On-Behalf-Of for the first-party app.
    /// </summary>
    [NonDebuggable]
    procedure AcquireGraphApiTokenDelegated(): SecretText
    var
        OAuth2: Codeunit OAuth2;
        LookupState: Codeunit "Fabric Platform Lookup State";
        AccessToken: SecretText;
        Scopes: List of [Text];
    begin
        // Test-injection seam: unit tests pre-seed a token to bypass the platform flow.
        if LookupState.HasGraphApiToken() then
            exit(LookupState.GetGraphApiToken());

        Scopes.Add('https://graph.microsoft.com/User.Read');
        OAuth2.AcquireOnBehalfOfToken('', Scopes, AccessToken);
        if AccessToken.IsEmpty() then
            Error(GraphApiTokenErr);
        exit(AccessToken);
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
        Scopes: List of [Text];
    begin
        // Test-injection seam: unit tests pre-seed a token to bypass the platform flow.
        if LookupState.HasFabricApiToken() then
            exit(LookupState.GetFabricApiToken());

#if not CLEAN29
#pragma warning disable AL0432
        if IsCustomAppEnabled() then
            exit(AcquireFabricApiTokenWithCustomApp());
#pragma warning restore AL0432
#endif

        Scopes.Add('https://api.fabric.microsoft.com/Workspace.ReadWrite.All');
        OAuth2.AcquireOnBehalfOfToken('', Scopes, AccessToken);
        if AccessToken.IsEmpty() then
            Error(FabricApiTokenErr);
        exit(AccessToken);
    end;

#if not CLEAN29
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
        if GetClientId() = '' then
            Error(ClientIdRequiredErr);

        AuthorityTenantId := GetTenantId();
        if AuthorityTenantId = '' then
            Error(TenantIdRequiredErr);

        OAuthAuthorityUrl := StrSubstNo(OAuthAuthorityUrlTok, AuthorityTenantId);
        Scopes.Add('https://api.fabric.microsoft.com/.default');
        OAuth2.GetDefaultRedirectUrl(RedirectUrl);

        OAuth2.AcquireTokenByAuthorizationCode(
            GetClientId(),
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
#endif
}
