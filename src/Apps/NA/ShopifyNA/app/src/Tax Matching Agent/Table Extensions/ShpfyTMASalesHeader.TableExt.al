namespace Microsoft.Integration.Shopify;

using Microsoft.Sales.Document;

/// <summary>
/// TableExtension Shpfy TMA Sales Header (ID 30477) extends Sales Header.
/// Carries the Tax Matching Agent marker forward from the Shopify order so
/// the Sales Order page can surface a non-blocking review prompt.
/// </summary>
tableextension 30477 "Shpfy TMA Sales Header" extends "Sales Header"
{
    fields
    {
        field(30476; "Tax Match Applied"; Boolean)
        {
            Caption = 'Tax Match Applied';
            DataClassification = SystemMetadata;
            Editable = false;
            ToolTip = 'Specifies that the Tax Matching Agent populated the Tax Area Code on the originating Shopify order. Use the Review Tax Match action to review the AI-generated decisions.';
        }
    }
}
