// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

/// <summary>
/// TableExtension Shpfy TMA Shop (ID 30470) extends Shpfy Shop.
/// Adds Tax Matching Agent configuration fields to the Shop table.
/// </summary>
tableextension 30470 "Shpfy TMA Shop" extends "Shpfy Shop"
{
    fields
    {
        field(30470; "Tax Matching Agent Enabled"; Boolean)
        {
            Caption = 'Tax Matching Agent Enabled';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether Tax Matching Agent is enabled for this shop.';
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
            InitValue = true;
            ToolTip = 'Specifies whether the system can create new Tax Areas when no exact match exists.';
        }
        field(30473; "Tax Area Naming Pattern"; Text[20])
        {
            Caption = 'Tax Area Naming Pattern';
            DataClassification = CustomerContent;
            InitValue = 'SHPFY-';
            ToolTip = 'Specifies the prefix used when auto-creating Tax Area codes.';
        }
        field(30474; "Tax Match Review Mode"; Enum "Shpfy Tax Match Review Mode")
        {
            Caption = 'Tax Match Review Mode';
            DataClassification = CustomerContent;
            InitValue = Always;
            ToolTip = 'Specifies when an order matched by the Tax Matching Agent is held until a user approves the tax match on the Tax Match Review page. Always holds every matched order (default). Low Confidence Only holds an order only when at least one match is not high confidence (including a match to a provisional, agent-created Tax Jurisdiction). Never does not hold orders for review preference. A rate conflict or an incomplete match always holds the order regardless of this setting.';
        }
    }
}
