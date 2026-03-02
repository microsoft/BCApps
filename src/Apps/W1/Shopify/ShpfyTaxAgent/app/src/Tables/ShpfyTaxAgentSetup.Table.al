// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

/// <summary>
/// Setup table for the Shopify Tax Matching Agent.
/// Keyed by Shop Code: each shop can have at most one tax matching agent.
/// </summary>
table 30470 "Shpfy Tax Agent Setup"
{
    Access = Internal;
    Caption = 'Shopify Tax Agent Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Shop Code"; Code[20])
        {
            Caption = 'Shop Code';
            DataClassification = CustomerContent;
            TableRelation = "Shpfy Shop";
        }
        field(2; "User Security ID"; Guid)
        {
            Caption = 'User Security ID';
            DataClassification = SystemMetadata;
        }
        field(3; "Auto Create Tax Jurisdictions"; Boolean)
        {
            Caption = 'Auto Create Tax Jurisdictions';
            DataClassification = CustomerContent;
        }
        field(4; "Auto Create Tax Areas"; Boolean)
        {
            Caption = 'Auto Create Tax Areas';
            DataClassification = CustomerContent;
        }
        field(5; "Tax Area Naming Pattern"; Text[50])
        {
            Caption = 'Tax Area Naming Pattern';
            DataClassification = CustomerContent;
            InitValue = 'SHPFY-AUTO-';
        }
    }

    keys
    {
        key(PK; "Shop Code")
        {
            Clustered = true;
        }
        key(Key1; "User Security ID")
        {
        }
    }
}
