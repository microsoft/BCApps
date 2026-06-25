namespace Microsoft.Sample.Loyalty;

codeunit 50109 "Loyalty Audit Subscriber"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Loyalty Events", 'OnAfterPostPoints', '', false, false)]
    local procedure HandleOnAfterPostPoints(var LoyaltyMember: Record "Loyalty Member")
    begin
        SendExternalAuditEmail(LoyaltyMember);
    end;

    local procedure SendExternalAuditEmail(var LoyaltyMember: Record "Loyalty Member")
    var
        Client: HttpClient;
        Content: HttpContent;
        Response: HttpResponseMessage;
    begin
        Content.WriteFrom(StrSubstNo('{"member":"%1"}', LoyaltyMember."No."));
        Client.Post('https://audit.contoso.example/loyalty', Content, Response);
    end;
}
