// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

/// <summary>
/// Temporary buffer table for storing dimension entry references during batch processing operations.
/// Maps sequential numbers to dimension entry numbers for efficient processing and lookup scenarios.
/// </summary>
/// <remarks>
/// Used for dimension correction processes, batch updates, and scenarios requiring temporary dimension entry tracking.
/// Provides dual indexing for both sequential access and dimension entry number lookup.
/// </remarks>
table 373 "Dimension Entry Buffer"
{
    Caption = 'Dimension Entry Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Sequential number for ordering and iteration during batch processing.
        /// </summary>
        field(1; "No."; Integer)
        {
            Caption = 'No.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Reference to the actual dimension entry number being processed or tracked.
        /// </summary>
        field(2; "Dimension Entry No."; Integer)
        {
            Caption = 'Dimension Entry No.';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Dimension Entry No.")
        {
        }
    }

    fieldgroups
    {
    }
}

