codeunit 131015 "Library - Azure AD Auth Flow"
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    var
        TokenAvailable: Boolean;
        TokenByAuthCodeTxt: Label 'TokenByAuthCode', Locked = true;
        TokenByAuthCodeWithCredsTxt: Label 'TokenByAuthCodeWithCreds', Locked = true;
        TokenFromCacheTxt: Label 'TokenFromCache', Locked = true;
        TokenFromCacheWithCredentialsTxt: Label 'TokenFromCacheWithCredentials', Locked = true;
        SaasClientIdTxt: Label '11111111-1111-1111-1111-111111111111', Locked = true;
        CachedTokenAvailable: Boolean;
        ClientIdAvailable: Boolean;
        GuestTokenAvailable: Boolean;
        GuestTokenTxt: Label 'GuestTokenTxt', Locked = true;

    local procedure CanHandle(): Boolean
    var
        AzureADMgtSetup: Record "Azure AD Mgt. Setup";
    begin
        if AzureADMgtSetup.Get() then
            exit(AzureADMgtSetup."Auth Flow Codeunit ID" = CODEUNIT::"Library - Azure AD Auth Flow");

        exit(false);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Azure AD Auth Flow", 'OnInitialize', '', false, false)]
    local procedure OnInitialize(RedirectUri: Text; var AzureADAuthFlow: DotNet ALAzureAdCodeGrantFlow)
    var
        Uri: DotNet Uri;
    begin
        if CanHandle() then
            AzureADAuthFlow := AzureADAuthFlow.ALAzureAdCodeGrantFlow(Uri.Uri(RedirectUri));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Azure AD Auth Flow", 'OnAcquireTokenByAuthorizationCode', '', false, false)]
    local procedure OnAcquireTokenByAuthorizationCode(AuthorizationCode: Text; ResourceName: Text; var AccessToken: Text)
    begin
        if CanHandle() and TokenAvailable then
            AccessToken := TokenByAuthCodeTxt;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Azure AD Auth Flow", 'OnAcquireTokenByAuthorizationCodeWithCredentials', '', false, false)]
    local procedure OnAcquireTokenByAuthorizationCodeWithCredentials(AuthorizationCode: Text; ClientID: Text; ApplicationKey: Text; ResourceName: Text; var AccessToken: Text)
    begin
        if CanHandle() and TokenAvailable then
            AccessToken := TokenByAuthCodeWithCredsTxt;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Azure AD Auth Flow", 'OnAcquireTokenFromCache', '', false, false)]
    local procedure OnAcquireTokenFromCache(ResourceName: Text; var AccessToken: Text)
    begin
        if CanHandle() and CachedTokenAvailable then
            AccessToken := TokenFromCacheTxt;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Azure AD Auth Flow", 'OnAcquireTokenFromCacheWithCredentials', '', false, false)]
    local procedure OnAcquireTokenFromCacheWithCredentials(ClientID: Text; AppKey: Text; ResourceName: Text; var AccessToken: Text)
    begin
        if CanHandle() and CachedTokenAvailable then
            AccessToken := TokenFromCacheWithCredentialsTxt;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Azure AD Auth Flow", 'OnAcquireGuestToken', '', false, false)]
    local procedure OnAcquireGuestToken(ResourceName: Text; GuestTenantId: Text; var AccessToken: Text)
    begin
        if CanHandle() and GuestTokenAvailable then
            AccessToken := GuestTokenTxt;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Azure AD Auth Flow", 'OnGetSaasClientId', '', false, false)]
    local procedure OnGetSaasClientId(var ClientID: Text)
    begin
        if CanHandle() and ClientIdAvailable then
            ClientID := SaasClientIdTxt;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Azure AD Auth Flow", 'OnCheckProvider', '', false, false)]
    local procedure OnCheckProvider(var Result: Boolean)
    begin
        if CanHandle() then
            Result := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Azure AD Auth Flow", 'OnCreateExchangeServiceWrapperWithToken', '', false, false)]
    local procedure OnCreateExchangeServiceWrapperWithToken(Token: Text; var Service: DotNet ExchangeServiceWrapper)
    var
        ServiceFactory: DotNet ServiceWrapperFactory;
    begin
        if CanHandle() then
            Service := ServiceFactory.CreateServiceWrapper2013();
    end;

    procedure SetTokenAvailable(Available: Boolean)
    begin
        TokenAvailable := Available;
    end;

    procedure SetCachedTokenAvailable(Available: Boolean)
    begin
        CachedTokenAvailable := Available;
    end;

    procedure SetClientIdAvailable(Available: Boolean)
    begin
        ClientIdAvailable := Available;
    end;

    procedure SetGuestTokenAvailable(Available: Boolean)
    begin
        GuestTokenAvailable := Available;
    end;
}

