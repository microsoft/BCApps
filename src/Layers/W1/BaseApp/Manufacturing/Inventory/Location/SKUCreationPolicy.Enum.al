namespace Microsoft.Inventory.Location;

enum 7351 "SKU Creation Policy"
{
    Extensible = true;

    value(0; Allowed)
    {
        Caption = 'Allowed';
    }
    value(1; "Blocked")
    {
        Caption = 'Blocked';
    }
}