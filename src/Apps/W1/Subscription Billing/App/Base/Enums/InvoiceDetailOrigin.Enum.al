namespace Microsoft.SubscriptionBilling;

enum 8021 "Invoice Detail Origin"
{
    Extensible = true;

    value(0; "Product Name (default)")
    {
        Caption = 'Product Name (default)';
    }
    value(1; "Subscription Line")
    {
        Caption = 'Subscription Line';
    }
}
