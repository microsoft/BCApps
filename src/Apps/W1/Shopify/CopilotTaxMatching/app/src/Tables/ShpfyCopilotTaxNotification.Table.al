namespace Microsoft.Integration.Shopify;

using Microsoft.Finance.SalesTax;

/// <summary>
/// Table Shpfy Copilot Tax Notification (ID 30476).
/// Tracks per-(Sales Header, user) Copilot-tax review prompts so the BC Sales Order page
/// can fire a non-blocking notification on first open and suppress it once the user
/// acknowledges the review.
/// </summary>
table 30476 "Shpfy Copilot Tax Notification"
{
    Caption = 'Shopify Copilot Tax Notification';
    DataClassification = SystemMetadata;
    InherentPermissions = RIMDX;
    InherentEntitlements = RIMDX;
    ReplicateData = false;
    Access = Internal;

    fields
    {
        field(1; "Sales Header SystemId"; Guid)
        {
            Caption = 'Sales Header SystemId';
            DataClassification = SystemMetadata;
        }
        field(2; "User Id"; Code[50])
        {
            Caption = 'User Id';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(10; "Notification ID"; Guid)
        {
            Caption = 'Notification ID';
            DataClassification = SystemMetadata;
        }
        field(20; Created; DateTime)
        {
            Caption = 'Created';
            DataClassification = SystemMetadata;
        }
        field(30; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            DataClassification = SystemMetadata;
            TableRelation = "Tax Area".Code;
        }
        field(40; Reviewed; Boolean)
        {
            Caption = 'Reviewed';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Sales Header SystemId", "User Id")
        {
            Clustered = true;
        }
    }
}
