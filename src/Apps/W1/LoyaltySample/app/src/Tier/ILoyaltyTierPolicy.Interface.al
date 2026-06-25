namespace Microsoft.Sample.Loyalty;

interface ILoyaltyTierPolicy
{
    procedure CalcDiscount(Amount: Decimal): Decimal;
    procedure GetTierLabel(): Text;
}
