// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

/// <summary>
/// Provides parameter storage for the undo sales shipment line process.
/// </summary>
table 5825 "Undo Sales Shpt. Line Params"
{
    TableType = Temporary;

    fields
    {
        /// <summary>
        /// Specifies the unique identifier for the parameter record.
        /// </summary>
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Indicates whether to suppress the confirmation dialog during the undo process.
        /// </summary>
        field(2; "Hide Dialog"; Boolean)
        {
            Caption = 'Hide Dialog';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }
}
