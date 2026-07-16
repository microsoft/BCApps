namespace Microsoft.Integration.Shopify;

/// <summary>
/// PageExtension Shpfy Copilot Tax Shop Card (ID 30470) extends Shpfy Shop Card.
/// Adds a Copilot Tax Matching tab to the Shop Card. Dependent settings are disabled until
/// their prerequisite is set, so a field that has no effect cannot be edited.
/// </summary>
pageextension 30470 "Shpfy Copilot Tax Shop Card" extends "Shpfy Shop Card"
{
    layout
    {
        addlast(content)
        {
            group(CopilotTaxMatching)
            {
                Caption = 'Copilot Tax Matching';

                field("Copilot Tax Matching Enabled"; Rec."Copilot Tax Matching Enabled")
                {
                    ApplicationArea = All;
                }
                field("Auto Create Tax Jurisdictions"; Rec."Auto Create Tax Jurisdictions")
                {
                    ApplicationArea = All;
                    Enabled = Rec."Copilot Tax Matching Enabled";
                }
                field("Auto Create Tax Areas"; Rec."Auto Create Tax Areas")
                {
                    ApplicationArea = All;
                    Enabled = Rec."Copilot Tax Matching Enabled";
                }
                field("Tax Area Naming Pattern"; Rec."Tax Area Naming Pattern")
                {
                    ApplicationArea = All;
                    Enabled = Rec."Copilot Tax Matching Enabled" and Rec."Auto Create Tax Areas";
                }
                field("Tax Match Review Required"; Rec."Tax Match Review Required")
                {
                    ApplicationArea = All;
                    Enabled = Rec."Copilot Tax Matching Enabled";
                }
            }
        }
    }
}
