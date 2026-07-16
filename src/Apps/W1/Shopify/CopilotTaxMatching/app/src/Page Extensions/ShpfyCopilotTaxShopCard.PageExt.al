namespace Microsoft.Integration.Shopify;

/// <summary>
/// PageExtension Shpfy Copilot Tax Shop Card (ID 30470) extends Shpfy Shop Card.
/// Adds a Copilot Tax Matching tab to the Shop Card.
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

                    trigger OnValidate()
                    begin
                        UpdateControlState();
                        CurrPage.Update(false);
                    end;
                }
                field("Auto Create Tax Jurisdictions"; Rec."Auto Create Tax Jurisdictions")
                {
                    ApplicationArea = All;
                    Enabled = CopilotTaxMatchingEnabled;
                }
                field("Auto Create Tax Areas"; Rec."Auto Create Tax Areas")
                {
                    ApplicationArea = All;
                    Enabled = CopilotTaxMatchingEnabled;

                    trigger OnValidate()
                    begin
                        UpdateControlState();
                        CurrPage.Update(false);
                    end;
                }
                field("Tax Area Naming Pattern"; Rec."Tax Area Naming Pattern")
                {
                    ApplicationArea = All;
                    Enabled = AutoCreateTaxAreasEnabled;
                }
                field("Tax Match Review Required"; Rec."Tax Match Review Required")
                {
                    ApplicationArea = All;
                    Enabled = CopilotTaxMatchingEnabled;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        UpdateControlState();
    end;

    local procedure UpdateControlState()
    begin
        CopilotTaxMatchingEnabled := Rec."Copilot Tax Matching Enabled";
        AutoCreateTaxAreasEnabled := Rec."Copilot Tax Matching Enabled" and Rec."Auto Create Tax Areas";
    end;

    var
        CopilotTaxMatchingEnabled: Boolean;
        AutoCreateTaxAreasEnabled: Boolean;
}
