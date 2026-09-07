// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

/// <summary>
/// TableExtension Shpfy TMA Order Header (ID 30476) extends Shpfy Order Header.
/// Marks orders whose Tax Area was populated by Tax Matching Agent, so the
/// status can propagate to the resulting Sales Header for human review, flags
/// orders that must be held for review because a matched rate conflicts with BC,
/// and flags orders where one or more tax lines could not be resolved to a
/// jurisdiction (the model returned UNKNOWN) and so must be completed by a human.
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
            ToolTip = 'Specifies whether a user has approved the tax match for this order. Depending on the shop''s Tax Match Review Mode, a Sales Document is not created until the match is approved on the Tax Match Review page.';
        }
        field(30478; "Tax Rate Conflict"; Boolean)
        {
            Caption = 'Tax Rate Conflict';
            DataClassification = SystemMetadata;
            Editable = false;
            ToolTip = 'Specifies whether the Tax Matching Agent matched a tax jurisdiction whose Business Central Tax Detail rate differs from the rate Shopify charged. Such an order is always held for human review, regardless of the shop''s Tax Match Review Mode, so the rate difference can be accepted or corrected before a Sales Document is created.';
        }
        field(30479; "Tax Match Incomplete"; Boolean)
        {
            Caption = 'Tax Match Incomplete';
            DataClassification = SystemMetadata;
            Editable = false;
            ToolTip = 'Specifies whether the Tax Matching Agent could not resolve one or more tax lines to a Tax Jurisdiction (the model returned UNKNOWN, e.g. for an unrecognizable or adversarial tax-line title). Such an order is always held for human review, regardless of the shop''s Tax Match Review Mode, so a user can assign the missing Tax Jurisdiction before a Sales Document is created.';
        }
        field(30480; "Tax Match Low Confidence"; Boolean)
        {
            Caption = 'Tax Match Low Confidence';
            DataClassification = SystemMetadata;
            Editable = false;
            ToolTip = 'Specifies whether the Tax Matching Agent produced at least one match on this order that is not high confidence. This includes a match to a provisional (agent-created, not yet verified) Tax Jurisdiction, which is always forced to low confidence. When the shop uses the Low Confidence Only review mode, such an order is held for human review.';
        }
    }

    keys
    {
        key(TMASalesOrderNo; "Sales Order No.")
        {
        }
    }
}
