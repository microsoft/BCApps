namespace Microsoft.FabricExport;

codeunit 9123 "Fabric Platform Lookup State"
{
    SingleInstance = true;
    Access = Internal;

    var
        CachedFabricApiToken: SecretText;
        FabricApiTokenExpiry: DateTime;

    [NonDebuggable]
    procedure SetFabricApiToken(Token: SecretText; ExpiresInSeconds: Integer)
    begin
        CachedFabricApiToken := Token;
        // Subtract 60 s safety margin so the token is refreshed before actual expiry.
        if ExpiresInSeconds > 60 then
            FabricApiTokenExpiry := CurrentDateTime() + (ExpiresInSeconds - 60) * 1000
        else
            FabricApiTokenExpiry := CurrentDateTime();
    end;

    [NonDebuggable]
    procedure GetFabricApiToken(): SecretText
    begin
        exit(CachedFabricApiToken);
    end;

    procedure HasFabricApiToken(): Boolean
    begin
        exit((FabricApiTokenExpiry <> 0DT) and (CurrentDateTime() < FabricApiTokenExpiry));
    end;

    procedure ClearFabricApiToken()
    var
        EmptySecret: SecretText;
    begin
        CachedFabricApiToken := EmptySecret;
        FabricApiTokenExpiry := 0DT;
    end;
}
