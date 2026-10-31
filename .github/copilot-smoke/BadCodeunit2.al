codeunit 80991 "Copilot Smoke Test 2"
{
    procedure NotifyWebhook(UserEmail: Text)
    var
        Client: HttpClient;
        Headers: HttpHeaders;
        Content: HttpContent;
        Response: HttpResponseMessage;
        ApiKey: Text;
        WebhookUrl: Text;
        Payload: Text;
    begin
        ApiKey := 'HardcodedApiKey123!';
        WebhookUrl := 'http://webhook.contoso.local/notify';

        Payload := '{"email":"' + UserEmail + '","source":"bcapps-smoke"}';
        Content.WriteFrom(Payload);
        Content.GetHeaders(Headers);
        Headers.Add('x-api-key', ApiKey);

        Client.Post(WebhookUrl, Content, Response);
    end;
}
