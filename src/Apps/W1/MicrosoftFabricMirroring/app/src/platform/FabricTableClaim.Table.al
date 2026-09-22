namespace Microsoft.FabricExport;

table 48533 "Fabric Table Claim"
{
    // Records who selected each row in the platform Tenant Fabric Tables. A platform row
    // is kept as long as at least one claim exists, and is only removed when its last
    // claim is released — so a manually-added table is never deleted by package deactivation.
    Caption = 'Fabric Table Claim';
    Access = Internal;
    DataClassification = SystemMetadata;
    DataPerCompany = false;

    fields
    {
        field(1; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            NotBlank = true;
        }
        field(2; "Source Type"; Enum "Fabric Table Claim Source")
        {
            Caption = 'Source Type';
        }
        field(3; "Package Code"; Code[20])
        {
            // Blank for a Manual claim; the config package code for a Package claim.
            Caption = 'Package Code';
        }
    }

    keys
    {
        key(PK; "Table ID", "Source Type", "Package Code")
        {
            Clustered = true;
        }
        key(TableID; "Table ID")
        {
        }
    }
}
