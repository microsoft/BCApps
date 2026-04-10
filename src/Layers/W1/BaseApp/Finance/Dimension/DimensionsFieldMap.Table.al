// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

/// <summary>
/// Maps dimension field numbers for tables to support dimension processing operations.
/// Stores field number mappings for global dimension fields and ID fields across Business Central tables.
/// </summary>
/// <remarks>
/// Used by dimension management processes to identify which fields contain dimension information.
/// Supports dimension update operations by providing field number mappings for automated processing.
/// </remarks>
table 8383 "Dimensions Field Map"
{
    Caption = 'Dimensions Field Map';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Unique identifier of the table for dimension field mapping.
        /// </summary>
        field(1; "Table No."; Integer)
        {
            Caption = 'Table No.';
        }
        /// <summary>
        /// Field number for global dimension 1 in the mapped table.
        /// </summary>
        field(2; "Global Dim.1 Field No."; Integer)
        {
            Caption = 'Global Dim.1 Field No.';
        }
        /// <summary>
        /// Field number for global dimension 2 in the mapped table.
        /// </summary>
        field(3; "Global Dim.2 Field No."; Integer)
        {
            Caption = 'Global Dim.2 Field No.';
        }
        /// <summary>
        /// Field number for the primary identifier field in the mapped table.
        /// </summary>
        field(4; "ID Field No."; Integer)
        {
            Caption = 'ID Field No.';
        }
    }

    keys
    {
        key(Key1; "Table No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

