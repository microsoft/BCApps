// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Dimension;

using Microsoft.Finance.Dimension;

/// <summary>
/// Extends the Dimension Value table with Intercompany-specific fields for dimension value mapping.
/// Enables mapping between company dimension values and intercompany dimension values for cross-company transactions.
/// </summary>
tableextension 8402 "IC Dimension Value" extends "Dimension Value"
{
    fields
    {
        /// <summary>
        /// Maps this dimension value to an intercompany dimension for transactions between related companies.
        /// Must correspond to a valid IC dimension in the intercompany setup.
        /// </summary>
        field(10; "Map-to IC Dimension Code"; Code[20])
        {
            Caption = 'Map-to IC Dimension Code';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the intercompany''s dimension code associated with the dimension of the current company.';

            trigger OnValidate()
            begin
                if "Map-to IC Dimension Code" <> xRec."Map-to IC Dimension Code" then
                    Validate("Map-to IC Dimension Value Code", '');
            end;
        }
        /// <summary>
        /// Maps this dimension value to a specific intercompany dimension value code.
        /// Used for automatic translation during intercompany transactions.
        /// </summary>
        field(11; "Map-to IC Dimension Value Code"; Code[20])
        {
            Caption = 'Map-to IC Dimension Value Code';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies which intercompany dimension value corresponds to the dimension value on the line.';
            TableRelation = "IC Dimension Value".Code where("Dimension Code" = field("Map-to IC Dimension Code"));
        }
    }
}
