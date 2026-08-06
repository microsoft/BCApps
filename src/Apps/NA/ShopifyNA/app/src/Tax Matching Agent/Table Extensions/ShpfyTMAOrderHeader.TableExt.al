namespace Microsoft.Integration.Shopify;

/// <summary>
/// TableExtension Shpfy TMA Order Header (ID 30476) extends Shpfy Order Header.
/// Marks orders whose Tax Area was populated by Tax Matching Agent, so the
/// status can propagate to the resulting Sales Header for human review, and flags
/// orders that must be held for review because a matched rate conflicts with BC.
/// </summary>
tableextension 30476 "Shpfy TMA Order Header" extends "Shpfy Order Header"
{
    fields
    {
        field(30476; "Tax Match Applied"; Boolean)
        {
            Caption = 'Tax Match Applied';
            DataClassification = SystemMetadata;
            Editable = false;
            ToolTip = 'Specifies whether Tax Matching Agent populated the Tax Area Code on this Shopify order.';
        }
        field(30477; "Tax Match Reviewed"; Boolean)
        {
            Caption = 'Tax Match Reviewed';
            DataClassification = SystemMetadata;
            Editable = false;
            ToolTip = 'Specifies whether a user has approved the tax match for this order. When the shop has Tax Match Review Required enabled, a Sales Document is not created until the match is approved on the Tax Match Review page.';
        }
        field(30478; "Tax Rate Conflict"; Boolean)
        {
            Caption = 'Tax Rate Conflict';
            DataClassification = SystemMetadata;
            Editable = false;
            ToolTip = 'Specifies whether the Tax Matching Agent matched a tax jurisdiction whose Business Central Tax Detail rate differs from the rate Shopify charged. Such an order is always held for human review, regardless of the Tax Match Review Required setting, so the rate difference can be accepted or corrected before a Sales Document is created.';
        }
    }
}
