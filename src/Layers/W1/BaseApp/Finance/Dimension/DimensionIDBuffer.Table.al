// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

/// <summary>
/// Temporary buffer table for managing dimension ID assignments and hierarchical dimension processing.
/// Stores parent-child relationships between dimensions for complex dimension operations and ID management.
/// </summary>
/// <remarks>
/// Used for dimension set operations, change global dimensions functionality, and dimension tree processing.
/// Provides efficient lookup by both composite keys and individual ID values.
/// </remarks>
table 353 "Dimension ID Buffer"
{
    Caption = 'Dimension ID Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Identifier of the parent dimension or dimension set for hierarchical processing.
        /// </summary>
        field(1; "Parent ID"; Integer)
        {
            Caption = 'Parent ID';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Code of the dimension being processed or assigned an ID.
        /// </summary>
        field(2; "Dimension Code"; Code[20])
        {
            Caption = 'Dimension Code';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Code of the dimension value being processed or assigned an ID.
        /// </summary>
        field(3; "Dimension Value"; Code[20])
        {
            Caption = 'Dimension Value';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Unique identifier assigned to this dimension combination for reference and lookup.
        /// </summary>
        field(4; ID; Integer)
        {
            Caption = 'ID';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Parent ID", "Dimension Code", "Dimension Value")
        {
            Clustered = true;
        }
        key(Key2; ID)
        {
        }
    }

    fieldgroups
    {
    }
}

