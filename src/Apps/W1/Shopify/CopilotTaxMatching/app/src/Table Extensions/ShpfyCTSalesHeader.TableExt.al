namespace Microsoft.Integration.Shopify;

using Microsoft.Sales.Document;

/// <summary>
/// TableExtension Shpfy CT Sales Header (ID 30477) extends Sales Header.
/// Carries the Copilot tax matching marker forward from the Shopify order so
/// the Sales Order page can surface a non-blocking review prompt.
/// </summary>
tableextension 30477 "Shpfy CT Sales Header" extends "Sales Header"
{
    fields
    {
        field(30476; "Copilot Tax Match Applied"; Boolean)
        {
            Caption = 'Copilot Tax Match Applied';
            DataClassification = SystemMetadata;
            Editable = false;
            ToolTip = 'Specifies that Copilot populated the Tax Area Code on the originating Shopify order. Use the Show Copilot Tax Decisions action to review the AI-generated decisions.';
        }
    }
}
