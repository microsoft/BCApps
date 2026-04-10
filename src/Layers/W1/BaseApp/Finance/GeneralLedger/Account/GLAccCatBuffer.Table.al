// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Account;

/// <summary>
/// Temporary buffer table for G/L account category processing.
/// Used for internal calculations and data manipulation related to account categories.
/// </summary>
table 8460 "G/L Acc. Cat. Buffer"
{
    DataClassification = SystemMetadata;
    TableType = Temporary;

    fields
    {
        /// <summary>
        /// Unique identifier for buffer table entries.
        /// </summary>
        field(1; "Entry No."; Integer)
        {
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
    }
}
