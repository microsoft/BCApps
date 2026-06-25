namespace Microsoft.Sample.Loyalty;

codeunit 50106 "Loyalty Order Validator"
{
    var
        TierPricing: Codeunit "Loyalty Tier Pricing";

    procedure ApplyDiscount(var LoyaltyMember: Record "Loyalty Member"; Amount: Decimal): Decimal
    begin
        exit(Amount - TierPricing.CalcDiscount(LoyaltyMember."Loyalty Tier", Amount));
    end;
}
