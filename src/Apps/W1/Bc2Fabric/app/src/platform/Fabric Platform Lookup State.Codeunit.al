namespace Microsoft.FabricExport;

#if not PTE
codeunit 150004 "Fabric Platform Lookup State"
#else
codeunit 50104 "Fabric Platform Lookup State"
#endif
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
        FabricApiTokenExpiry := CurrentDateTime() + (ExpiresInSeconds - 60) * 1000;
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
