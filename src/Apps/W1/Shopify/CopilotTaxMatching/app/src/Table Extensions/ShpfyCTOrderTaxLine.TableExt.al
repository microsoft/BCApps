namespace Microsoft.Integration.Shopify;

using Microsoft.Finance.SalesTax;

/// <summary>
/// TableExtension Shpfy CT Order Tax Line (ID 30480) extends Shpfy Order Tax Line.
/// Hosts the Tax Jurisdiction Code field that the Copilot matcher writes to. The
/// field lives in the Copilot app rather than the standard connector because the
/// connector itself does not read or write it — it is meaningful only when Copilot
/// Tax Matching is in use.
/// </summary>
tableextension 30480 "Shpfy CT Order Tax Line" extends "Shpfy Order Tax Line"
{
    fields
    {
        field(30476; "Tax Jurisdiction Code"; Code[10])
        {
            Caption = 'Tax Jurisdiction Code';
            DataClassification = CustomerContent;
            TableRelation = "Tax Jurisdiction";
            ToolTip = 'Specifies the Business Central Tax Jurisdiction that matches this Shopify tax line. Set by Copilot tax matching.';
        }
    }
}
