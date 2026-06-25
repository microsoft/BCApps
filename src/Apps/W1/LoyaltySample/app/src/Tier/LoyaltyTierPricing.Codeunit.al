namespace Microsoft.Sample.Loyalty;

codeunit 50105 "Loyalty Tier Pricing"
{
    procedure CalcDiscount(Tier: Enum "Loyalty Tier"; Amount: Decimal): Decimal
    begin
        case Tier of
            Tier::None:
                exit(0);
            Tier::Silver:
                exit(Amount * 0.05);
            Tier::Gold:
                exit(Amount * 0.10);
            Tier::Platinum:
                exit(Amount * 0.15);
        end;
    end;

    procedure GetTierLabel(Tier: Enum "Loyalty Tier"): Text
    begin
        case Tier of
            Tier::None:
                exit('Standard');
            Tier::Silver:
                exit('Silver Member');
            Tier::Gold:
                exit('Gold Member');
            Tier::Platinum:
                exit('Platinum Member');
        end;
    end;
}
