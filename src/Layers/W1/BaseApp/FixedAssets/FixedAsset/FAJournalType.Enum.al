namespace Microsoft.FixedAssets.Ledger;

enum 5621 "FA Journal Type"
{
    Extensible = true;

    value(0; "G/L")
    {
        Caption = 'G/L';
    }
    value(1; "Fixed Asset")
    {
        Caption = 'Fixed Asset';
    }
}