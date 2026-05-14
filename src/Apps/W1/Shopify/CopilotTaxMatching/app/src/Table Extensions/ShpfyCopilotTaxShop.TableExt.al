namespace Microsoft.Integration.Shopify;

/// <summary>
/// TableExtension Shpfy Copilot Tax Shop (ID 30470) extends Shpfy Shop.
/// Adds Copilot tax matching configuration fields to the Shop table.
/// </summary>
tableextension 30470 "Shpfy Copilot Tax Shop" extends "Shpfy Shop"
{
    fields
    {
        field(30470; "Copilot Tax Matching Enabled"; Boolean)
        {
            Caption = 'Copilot Tax Matching Enabled';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether Copilot tax matching is enabled for this shop.';
        }
        field(30471; "Auto Create Tax Jurisdictions"; Boolean)
        {
            Caption = 'Auto Create Tax Jurisdictions';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether the system can create new Tax Jurisdictions when no match is found.';
        }
        field(30472; "Auto Create Tax Areas"; Boolean)
        {
            Caption = 'Auto Create Tax Areas';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether the system can create new Tax Areas when no exact match exists.';
        }
        field(30473; "Tax Area Naming Pattern"; Text[20])
        {
            Caption = 'Tax Area Naming Pattern';
            DataClassification = CustomerContent;
            InitValue = 'SHPFY-';
            ToolTip = 'Specifies the prefix used when auto-creating Tax Area codes.';
        }
        field(30474; "Tax Match Review Required"; Boolean)
        {
            Caption = 'Copilot Tax Match Review Required';
            DataClassification = CustomerContent;
            InitValue = true;
            ToolTip = 'Specifies whether Sales Document creation is held until a user explicitly approves the Copilot tax match. When enabled (default), an order whose Tax Area was populated by Copilot cannot become a Sales Order until the Approve Copilot Tax Match action is taken on the Shopify order. When disabled, Sales Documents are created automatically and the user reviews them after the fact via the notification on the Sales Order page.';
        }
    }
}
