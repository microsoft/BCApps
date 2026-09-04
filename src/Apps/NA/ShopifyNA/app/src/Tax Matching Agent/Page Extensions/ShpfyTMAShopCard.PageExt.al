// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

using System.Telemetry;

/// <summary>
/// PageExtension Shpfy TMA Shop Card (ID 30470) extends Shpfy Shop Card.
/// Adds a Tax Matching Agent tab to the Shop Card. Dependent settings are disabled until
/// their prerequisite is set, so a field that has no effect cannot be edited.
/// </summary>
pageextension 30470 "Shpfy TMA Shop Card" extends "Shpfy Shop Card"
{
    layout
    {
        addlast(content)
        {
            group(TaxMatchingAgent)
            {
                Caption = 'Tax Matching Agent';

                field("Tax Matching Agent Enabled"; Rec."Tax Matching Agent Enabled")
                {
                    ApplicationArea = All;
                }
                field("Auto Create Tax Jurisdictions"; Rec."Auto Create Tax Jurisdictions")
                {
                    ApplicationArea = All;
                    Enabled = Rec."Tax Matching Agent Enabled";
                }
                field("Auto Create Tax Areas"; Rec."Auto Create Tax Areas")
                {
                    ApplicationArea = All;
                    Enabled = Rec."Tax Matching Agent Enabled";
                }
                field("Tax Area Naming Pattern"; Rec."Tax Area Naming Pattern")
                {
                    ApplicationArea = All;
                    Enabled = Rec."Tax Matching Agent Enabled" and Rec."Auto Create Tax Areas";
                }
                field("Tax Match Review Mode"; Rec."Tax Match Review Mode")
                {
                    ApplicationArea = All;
                    Enabled = Rec."Tax Matching Agent Enabled";
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        TMARegister: Codeunit "Shpfy TMA Register";
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        FeatureTelemetry.LogUptake('0000UN8', TMARegister.FeatureName(), Enum::"Feature Uptake Status"::Discovered);
    end;
}
