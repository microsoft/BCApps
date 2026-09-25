// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

using Microsoft.Finance.SalesTax;

/// <summary>
/// TableExtension Shpfy TMA Tax Jurisdiction (ID 30481) extends Tax Jurisdiction.
/// Records the provenance of Tax Jurisdictions that the Tax Matching Agent auto-created from
/// buyer-controlled Shopify data. A jurisdiction created by the agent is "provisional" until a
/// human verifies it: while it is Created by Agent and not yet Verified, a match to it is forced
/// to low confidence and held for review (unless the shop's review mode is Never, where nothing is
/// held), so the agent cannot silently trust master data it invented. Verified is set when a user
/// approves any order that uses the jurisdiction.
/// Jurisdictions created by a user/admin (or existing before this feature) keep Created by Agent =
/// false and are never quarantined, so no data migration is required.
/// </summary>
tableextension 30481 "Shpfy TMA Tax Jurisdiction" extends "Tax Jurisdiction"
{
    fields
    {
        field(30470; "Shpfy Created by Agent"; Boolean)
        {
            Caption = 'Created by Agent';
            DataClassification = SystemMetadata;
            Editable = false;
            ToolTip = 'Specifies whether the Tax Matching Agent auto-created this Tax Jurisdiction from a Shopify order. Such a jurisdiction is treated as provisional until a user has verified it by approving an order that uses it.';
        }
        field(30471; "Shpfy Verified"; Boolean)
        {
            Caption = 'Verified';
            DataClassification = SystemMetadata;
            Editable = false;
            ToolTip = 'Specifies whether an agent-created Tax Jurisdiction has been verified by a user. It is set the first time a user approves an order whose tax match uses this jurisdiction. Until then, any match to the jurisdiction is forced to low confidence and held for review.';
        }
    }
}
