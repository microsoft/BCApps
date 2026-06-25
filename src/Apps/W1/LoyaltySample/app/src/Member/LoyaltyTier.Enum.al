namespace Microsoft.Sample.Loyalty;

enum 50100 "Loyalty Tier"
{
    Extensible = true;

    value(0; None)
    {
        Caption = 'None';
    }
    value(1; Silver)
    {
        Caption = 'Silver';
    }
    value(2; Gold)
    {
        Caption = 'Gold';
    }
    value(3; Platinum)
    {
        Caption = 'Platinum';
    }
}
