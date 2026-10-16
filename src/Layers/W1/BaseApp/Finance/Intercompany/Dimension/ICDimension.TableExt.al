// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Dimension;

using Microsoft.Finance.Dimension;

/// <summary>
/// Extends the Dimension table with Intercompany-specific fields for dimension mapping.
/// Enables mapping between company dimensions and intercompany dimensions for cross-company transactions.
/// </summary>
tableextension 8401 "IC Dimension" extends Dimension
{
    fields
    {
        /// <summary>
        /// Maps this dimension to an intercompany dimension for transactions between related companies.
        /// When set, all dimension values are automatically mapped to the corresponding IC dimension.
        /// </summary>
        field(8; "Map-to IC Dimension Code"; Code[20])
        {
            Caption = 'Map-to IC Dimension Code';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies which intercompany dimension corresponds to the dimension on the line.';
            TableRelation = "IC Dimension";

            trigger OnValidate()
            var
                DimensionValue: Record "Dimension Value";
            begin
                if "Map-to IC Dimension Code" <> xRec."Map-to IC Dimension Code" then begin
                    DimensionValue.SetRange("Dimension Code", Code);
                    DimensionValue.ModifyAll("Map-to IC Dimension Code", "Map-to IC Dimension Code");
                    DimensionValue.ModifyAll("Map-to IC Dimension Value Code", '');
                end;
            end;
        }
    }
}
