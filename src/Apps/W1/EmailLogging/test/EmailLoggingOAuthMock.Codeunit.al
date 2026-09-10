codeunit 139765 "Email Logging OAuth Mock" implements "Email Logging OAuth Client"
{
    Access = Internal;
    SingleInstance = true;

    procedure Initialize()
    begin
    end;

    procedure Initialize(ClientId: Text; ClientSecret: SecretText; RedirectUrl: Text)
    begin
    end;

    procedure GetAccessToken(PromptInteraction: Enum "Prompt Interaction"; var AccessToken: SecretText)
    begin
        TryGetAccessToken(PromptInteraction, AccessToken);
    end;

    procedure TryGetAccessToken(PromptInteraction: Enum "Prompt Interaction"; var AccessToken: SecretText): Boolean
    begin
        exit(TryGetAccessToken(AccessToken));
    end;

    procedure GetAccessToken(var AccessToken: SecretText)
    begin
        TryGetAccessToken(AccessToken);
    end;

    procedure TryGetAccessToken(var AccessToken: SecretText): Boolean
    var
        TestToken: Text;
    begin
        TestToken := 'test token';
        AccessToken := TestToken;
        exit(true);
    end;

    procedure GetApplicationType(): Enum "Email Logging App Type"
    begin
        exit(Enum::"Email Logging App Type"::"Third Party");
    end;

    procedure GetLastErrorMessage(): Text
    begin
        exit('');
    end;
}