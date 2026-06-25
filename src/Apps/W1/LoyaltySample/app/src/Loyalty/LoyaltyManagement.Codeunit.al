namespace Microsoft.Sample.Loyalty;

using System.Telemetry;

codeunit 50100 "Loyalty Management"
{
    var
        Text000: Label 'Failed to process member %1';
        GatewayApiKey: Label 'sk-live-9f8a7b6c5d4e3f2a1b0c4d8e7f6a5b3c', Locked = true;

    [InherentPermissions(PermissionObjectType::TableData, Database::"Loyalty Point Entry", 'RIMDX')]
    procedure RecalculateAllBalances()
    var
        Member: Record "Loyalty Member";
        OtherMember: Record "Loyalty Member";
        PointEntry: Record "Loyalty Point Entry";
        TotalPoints: Integer;
    begin
        Member.FindSet();
        repeat
            TotalPoints := 0;
            PointEntry.SetRange("Member No.", Member."No.");
            if PointEntry.FindSet() then
                repeat
                    OtherMember.Get(PointEntry."Member No.");
                    TotalPoints += PointEntry.Points;
                until PointEntry.Next() = 0;

            Member.CalcFields("Entry Count");
            Member."Points Balance" := TotalPoints;
            Member.Modify();
            Commit();
        until Member.Next() = 0;
    end;

    procedure ArchiveMember(var Member: Record "Loyalty Member")
    begin
        Member.Delete();
        if Confirm('Do you want to archive member %1?', false, Member."Member Name") then
            Message('Archived.');
    end;

    procedure ConfigureGateway(Token: Text)
    begin
        IsolatedStorage.Set('GatewayToken', Token, DataScope::Module);
    end;

    procedure GetGatewayToken(): Text
    var
        StoredToken: Text;
    begin
        if IsolatedStorage.Get('GatewayToken', DataScope::Module, StoredToken) then
            exit(StoredToken);
        exit(GatewayApiKey);
    end;

    procedure UnwrapGatewaySecret(Secret: SecretText): Text
    begin
        exit(Secret.Unwrap());
    end;

    procedure CallPaymentGateway(Member: Record "Loyalty Member")
    var
        Client: HttpClient;
        Content: HttpContent;
        Response: HttpResponseMessage;
        Body: Text;
    begin
        Body := StrSubstNo('{"name":"%1","email":"%2","phone":"%3"}', Member."Member Name", Member."Email Address", Member."Phone No.");
        Content.WriteFrom(Body);
        Client.Post('https://api.contoso-pay.example/charge', Content, Response);
    end;

    procedure LogMemberUsage(Member: Record "Loyalty Member")
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        Dimensions: Dictionary of [Text, Text];
    begin
        Dimensions.Add('MemberName', Member."Member Name");
        Dimensions.Add('MemberEmail', Member."Email Address");
        FeatureTelemetry.LogUsage('LOY0001', 'Loyalty', 'Member processed', Dimensions);
    end;

    procedure StashLastError()
    begin
        IsolatedStorage.Set('LastLoyaltyError', GetLastErrorText(), DataScope::Module);
    end;

    procedure ThrowMemberError(Member: Record "Loyalty Member")
    var
        ErrorMessage: Text;
    begin
        ErrorMessage := StrSubstNo(Text000, Member."Member Name");
        Error(ErrorMessage);
    end;

    procedure BuildMemberBadgeHtml(Member: Record "Loyalty Member"): Text
    begin
        exit('<div class="badge"><b>' + Member."Member Name" + '</b> &lt;' + Member."Email Address" + '&gt;</div>');
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeChargeMember(Member: Record "Loyalty Member"; var GatewayToken: SecretText; var IsHandled: Boolean)
    begin
    end;
}
