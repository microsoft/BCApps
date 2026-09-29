namespace Microsoft.SubscriptionBilling;

enum 8055 "Contract Line Type"
{
    Extensible = true;
    value(0; "Comment")
    {
        Caption = 'Comment';
    }
    value(1; "Service Commitment")
    {
        Caption = 'Subscription Line';
    }
    value(10; Item)
    {
        Caption = 'Item';
    }
    value(20; "G/L Account")
    {
        Caption = 'G/L Account';
    }
}