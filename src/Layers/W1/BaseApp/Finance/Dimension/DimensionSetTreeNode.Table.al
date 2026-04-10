// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

/// <summary>
/// Optimized tree structure for dimension set creation and duplicate detection.
/// Enables efficient dimension set ID generation by tracking hierarchical dimension value combinations.
/// </summary>
/// <remarks>
/// Part of dimension set optimization architecture: prevents duplicate dimension sets through tree-based lookup.
/// Works with Dimension Set Entry to create unique dimension set IDs for transaction processing.
/// Tree structure allows fast traversal and duplicate detection during dimension set creation.
/// </remarks>
table 481 "Dimension Set Tree Node"
{
    Caption = 'Dimension Set Tree Node';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Parent node identifier in the dimension set tree hierarchy.
        /// </summary>
        field(1; "Parent Dimension Set ID"; Integer)
        {
            Caption = 'Parent Dimension Set ID';
        }
        /// <summary>
        /// Dimension value identifier used for tree node creation and lookup.
        /// </summary>
        field(2; "Dimension Value ID"; Integer)
        {
            Caption = 'Dimension Value ID';
        }
        /// <summary>
        /// Auto-generated unique identifier for the dimension set represented by this tree path.
        /// </summary>
        field(3; "Dimension Set ID"; Integer)
        {
            AutoIncrement = true;
            Caption = 'Dimension Set ID';
        }
        /// <summary>
        /// Indicates whether this dimension set is actively referenced by transaction data.
        /// </summary>
        field(4; "In Use"; Boolean)
        {
            Caption = 'In Use';
        }
    }

    keys
    {
        key(Key1; "Parent Dimension Set ID", "Dimension Value ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

