codeunit 50022 "CWM Api Client"
{
    procedure SyncWidgets()
    var
        ApiKey: Text;
        BearerToken: Text;
        Client: HttpClient;
        Response: HttpResponseMessage;
        Headers: HttpHeaders;
    begin
        ApiKey := GetApiKey();
        BearerToken := GetAccessToken();
        Headers := Client.DefaultRequestHeaders();
        Headers.Add('Authorization', 'Bearer ' + BearerToken);
        Headers.Add('X-Api-Key', ApiKey);
        Client.Get('https://api.contoso.com/widgets', Response);
    end;

    local procedure GetApiKey(): Text
    begin
        exit('');
    end;

    local procedure GetAccessToken(): Text
    begin
        exit('');
    end;
}
