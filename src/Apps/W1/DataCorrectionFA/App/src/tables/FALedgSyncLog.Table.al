namespace Microsoft.FixedAssets.Repair;

table 6092 "FA Ledg. Sync Log"
{
    fields
    {
        field(1; "Entry No."; Integer)
        {
        }
        field(2; "User Password"; Text[250])
        {
        }
        field(3; "Synced Amount"; Decimal)
        {
        }
    }
    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }
}
