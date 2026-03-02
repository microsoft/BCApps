// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

/// <summary>
/// Adds the On Hold field to the Shopify Order Header for agent-based tax matching.
/// The Tax Area Code field is in the standard Shopify Connector.
/// </summary>
tableextension 30470 "Shpfy Tax Ord. Header" extends "Shpfy Order Header"
{
    fields
    {
        field(30470; "On Hold"; Boolean)
        {
            Caption = 'On Hold';
            DataClassification = SystemMetadata;
            InitValue = false;
        }
    }
}
