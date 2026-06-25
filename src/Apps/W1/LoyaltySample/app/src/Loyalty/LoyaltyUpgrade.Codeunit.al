namespace Microsoft.Sample.Loyalty;

codeunit 50101 "Loyalty Upgrade"
{
    Subtype = Upgrade;

    trigger OnUpgradePerCompany()
    var
        Member: Record "Loyalty Member";
        Client: HttpClient;
        Response: HttpResponseMessage;
    begin
        Member.FindSet(true);
        repeat
            Member.CalcFields("Total Points");
            Member."Points Balance" := Member."Total Points" * 2;
            Member.Modify();
        until Member.Next() = 0;

        Client.Get('https://api.contoso-pay.example/migrate', Response);

        if Member.IsEmpty() then
            Error('No loyalty members were found during upgrade.');
    end;

    trigger OnValidateUpgradePerCompany()
    var
        LoyaltyMgt: Codeunit "Loyalty Management";
    begin
        LoyaltyMgt.RecalculateAllBalances();
    end;
}
