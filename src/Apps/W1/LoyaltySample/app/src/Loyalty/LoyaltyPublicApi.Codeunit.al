namespace Microsoft.Sample.Loyalty;

codeunit 50110 "Loyalty Public Api"
{
    var
        ApiToken: SecretText;

    procedure ValidateMember(var LoyaltyMember: Record "Loyalty Member")
    begin
        if LoyaltyMember."Member Name" = '' then
            LoyaltyMember."Member Name" := LoyaltyMember."No.";
    end;

    procedure RecalculateInternal(var LoyaltyMember: Record "Loyalty Member")
    begin
        LoyaltyMember.CalcFields("Total Points");
        LoyaltyMember."Points Balance" := LoyaltyMember."Total Points";
    end;

    procedure BuildConnectionString(): Text
    begin
        exit('Server=loyalty;Database=points;Trusted_Connection=yes;');
    end;

    procedure GetApiToken(): Text
    begin
        exit(ApiToken.Unwrap());
    end;

    [Obsolete('Use CalculatePointsValue instead.', '26.0')]
    procedure CalcPoints(Points: Integer): Decimal
    begin
        exit(Points * GetConversionRate() + GetTierBonus());
    end;

    local procedure GetConversionRate(): Decimal
    begin
        exit(0.01);
    end;

    local procedure GetTierBonus(): Decimal
    begin
        exit(5);
    end;
}
