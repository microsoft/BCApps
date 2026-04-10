// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension.Correction;

/// <summary>
/// Tracks invalidated dimension corrections caused by subsequent changes to dimension data.
/// Maintains hierarchical relationships between invalidation nodes for audit trail.
/// </summary>
table 2587 "Invalidated Dim Correction"
{
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Unique identifier for this invalidation node.
        /// </summary>
        field(1; "Node Id"; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Node Id';
            Editable = false;
            AutoIncrement = true;
        }

        /// <summary>
        /// Reference to the parent invalidation node for hierarchical tracking.
        /// </summary>
        field(2; "Parent Node Id"; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Parent Node Id';
            Editable = false;
        }

        /// <summary>
        /// Entry number of the dimension correction that was invalidated.
        /// </summary>
        field(3; "Invalidated Entry No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Invalidated Entry No.';
            Editable = false;
        }

        /// <summary>
        /// Entry number of the dimension correction that caused the invalidation.
        /// </summary>
        field(4; "Invalidated By Entry No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Invalidated By Entry No.';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Node Id")
        {
            Clustered = true;
        }
        key(Key2; "Invalidated Entry No.")
        {
        }
        key(Key3; "Invalidated By Entry No.")
        {
        }
        key(Key4; "Parent Node Id", "Invalidated Entry No.", "Invalidated By Entry No.")
        {
        }
    }
}
