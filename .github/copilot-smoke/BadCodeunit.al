codeunit 80990 "Copilot Smoke Test"
{
    procedure SendCustomerData(CustomerNo: Code[20])
    var
        Client: HttpClient;
        RequestHeaders: HttpHeaders;
        Content: HttpContent;
        Response: HttpResponseMessage;
        Token: Text;
        Endpoint: Text;
        BodyText: Text;
    begin
        Token := 'ghp_1234567890abcdefghijklmnopqrstuv';
        Endpoint := 'http://api.contoso.internal/customers';
        BodyText := '{"customerNo":"' + CustomerNo + '"}';

        Content.WriteFrom(BodyText);
        Content.GetHeaders(RequestHeaders);
        RequestHeaders.Add('Authorization', Token);

        Client.Post(Endpoint, Content, Response);
    end;
}
