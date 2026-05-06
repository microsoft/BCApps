namespace Microsoft.Integration.Shopify;

/// <summary>
/// TableExtension Shpfy CT Order Header (ID 30476) extends Shpfy Order Header.
/// Marks orders whose Tax Area was populated by Copilot tax matching, so the
/// status can propagate to the resulting Sales Header for human review.
/// </summary>
tableextension 30476 "Shpfy CT Order Header" extends "Shpfy Order Header"
{
    fields
    {
        field(30476; "Copilot Tax Match Applied"; Boolean)
        {
            Caption = 'Copilot Tax Match Applied';
            DataClassification = SystemMetadata;
            Editable = false;
            ToolTip = 'Specifies whether Copilot tax matching populated the Tax Area Code on this Shopify order.';
        }
        field(30477; "Copilot Tax Match Reviewed"; Boolean)
        {
            Caption = 'Copilot Tax Match Reviewed';
            DataClassification = SystemMetadata;
            Editable = false;
            ToolTip = 'Specifies whether a user has approved the Copilot tax match for this order. When the shop has Copilot Tax Match Review Required enabled, a Sales Document is not created until this flag is set via the Approve Copilot Tax Match action.';
        }
    }
}
