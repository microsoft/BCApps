#if not CLEANSCHEMA27 
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Deposit;

/// <summary>
/// Configuration table for mapping deposit page types to their corresponding object IDs.
/// Used for dynamic page selection in deposit management workflows.
/// </summary>
/// <remarks>
/// This table is obsolete and removed in version 27.0. Bank Deposits extension provides the required pages directly.
/// Previously used for North American localization deposit page mapping.
/// </remarks>
table 500 "Deposits Page Setup"
{
    DataClassification = SystemMetadata;
    ObsoleteReason = 'Pages used are the ones from the Bank Deposits extension. No other pages are provided, this table was needed when NA had it''s own pages. Open directly the required pages or run the required reports in the Bank Deposits extension.';
    ObsoleteState = Removed;
    ObsoleteTag = '27.0';

    fields
    {
        /// <summary>
        /// Type of deposit page or report being configured.
        /// Links to specific deposit workflow components.
        /// </summary>
        field(1; Id; Enum "Deposits Page Setup Key")
        {
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Object ID of the page or report associated with the deposit page type.
        /// References the actual AL object to be opened or executed.
        /// </summary>
        field(2; ObjectId; Integer)
        {
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; Id)
        {
            Clustered = true;
        }
    }
}

#endif