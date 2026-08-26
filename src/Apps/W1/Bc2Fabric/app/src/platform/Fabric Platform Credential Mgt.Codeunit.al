namespace Microsoft.Bc2Fabric;

using System.Azure.Identity;
using System.Security.Authentication;
using System.Security.Encryption;

codeunit 150005 "Fabric Platform Credential Mgt"
{
    Access = Internal;

    var
        ClientIdRequiredErr: Label 'Client ID must be filled in before acquiring a Fabric API token.';
#if BC2FABRIC_DEMO
        TenantIdRequiredErr: Label 'Microsoft Entra tenant ID could not be determined. Fill in the demo Tenant ID before acquiring a Fabric API token.';
#else
        TenantIdRequiredErr: Label 'Microsoft Entra tenant ID could not be determined.';
#endif
        FabricApiTokenInteractiveErr: Label 'Failed to acquire the Fabric API token interactively. Verify the app registration and that redirect URL %1 is registered.', Comment = '%1 = redirect URL';
        EncryptionNotEnabledErr: Label 'The Client Secret cannot be stored because data encryption is not enabled for this environment. An administrator must enable it first: search for ''Data Encryption Management'' and choose ''Activate Encryption''.';
#if BC2FABRIC_DEMO
        DemoUnencryptedSecretWarningMsg: Label 'DEMO MODE: Data encryption is not enabled, so the Client Secret is being stored unencrypted. Do not use this environment for anything beyond the demo.';
#endif

    procedure SetClientId(ClientId: Text)
    begin
        IsolatedStorage.Set('FabricPlat.ClientId', ClientId, DataScope::Module);
    end;

    procedure GetClientId(): Text
    var
        Value: Text;
    begin
        if IsolatedStorage.Get('FabricPlat.ClientId', DataScope::Module, Value) then
            exit(Value);
        exit('');
    end;

#if BC2FABRIC_DEMO
    procedure SetTenantId(TenantId: Text)
    begin
        IsolatedStorage.Set('FabricPlat.TenantId', TenantId, DataScope::Module);
    end;

    procedure GetTenantId(): Text
    var
        Value: Text;
    begin
        if IsolatedStorage.Get('FabricPlat.TenantId', DataScope::Module, Value) then
            exit(Value);
        exit('');
    end;
#endif

    procedure SetPrincipalId(PrincipalId: Text)
    begin
        IsolatedStorage.Set('FabricPlat.PrincipalId', PrincipalId, DataScope::Module);
    end;

    procedure GetPrincipalId(): Text
    var
        Value: Text;
    begin
        if IsolatedStorage.Get('FabricPlat.PrincipalId', DataScope::Module, Value) then
            exit(Value);
        exit('');
    end;

    procedure SetLakehouseName(LakehouseName: Text)
    begin
        IsolatedStorage.Set('FabricPlat.LakehouseName', LakehouseName, DataScope::Module);
    end;

    procedure GetLakehouseName(): Text
    var
        Value: Text;
    begin
        if IsolatedStorage.Get('FabricPlat.LakehouseName', DataScope::Module, Value) then
            exit(Value);
        exit('');
    end;

    [NonDebuggable]
    procedure SetClientSecret(ClientSecret: SecretText)
    var
        CryptographyManagement: Codeunit "Cryptography Management";
    begin
        if IsolatedStorage.Contains('FabricPlat.ClientSecret', DataScope::Module) then
            IsolatedStorage.Delete('FabricPlat.ClientSecret', DataScope::Module);

        if CryptographyManagement.IsEncryptionEnabled() then begin
            IsolatedStorage.SetEncrypted('FabricPlat.ClientSecret', ClientSecret, DataScope::Module);
            exit;
        end;

#if BC2FABRIC_DEMO
        if not IsDemoUnencryptedSecretFallbackAllowed() then
            Error(EncryptionNotEnabledErr);
        Message(DemoUnencryptedSecretWarningMsg);
        IsolatedStorage.Set('FabricPlat.ClientSecret', ClientSecret, DataScope::Module);
#else
        Error(EncryptionNotEnabledErr);
#endif
    end;

#if BC2FABRIC_DEMO
    local procedure IsDemoUnencryptedSecretFallbackAllowed(): Boolean
    begin
        exit(true);
    end;
#endif

    [NonDebuggable]
    procedure IsClientSecretSet(): Boolean
    begin
        exit(not GetClientSecretSecure().IsEmpty());
    end;

    procedure ClearTokenCache()
    var
        LookupState: Codeunit "Fabric Platform Lookup State";
    begin
        LookupState.ClearFabricApiToken();
    end;

    /// <summary>
    /// Acquires a delegated Fabric API token via authorization code flow (interactive browser prompt).
    /// The result is cached in-session for 1 hour. Will be replaced by MS first-party auth.
    /// </summary>
    [NonDebuggable]
    procedure AcquireFabricApiTokenDelegated(): SecretText
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

        if LookupState.HasFabricApiToken() then
            exit(LookupState.GetFabricApiToken());

        AuthorityTenantId := GetAuthorityTenantId();
        if AuthorityTenantId = '' then
            Error(TenantIdRequiredErr);

        OAuthAuthorityUrl := StrSubstNo('https://login.microsoftonline.com/%1/oauth2/v2.0/authorize', AuthorityTenantId);
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

    local procedure GetAuthorityTenantId(): Text
    var
        AzureADTenant: Codeunit "Azure AD Tenant";
#if BC2FABRIC_DEMO
        AuthorityTenantId: Text;
#endif
    begin
#if BC2FABRIC_DEMO
        AuthorityTenantId := GetTenantId();
        if AuthorityTenantId <> '' then
            exit(AuthorityTenantId);
#endif
        exit(AzureADTenant.GetAadTenantId());
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
