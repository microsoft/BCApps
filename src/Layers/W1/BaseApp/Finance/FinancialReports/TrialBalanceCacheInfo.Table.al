// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

/// <summary>
/// Stores metadata information for trial balance cache system operations.
/// Tracks cache last modified timestamp to support staleness detection and refresh operations.
/// </summary>
table 1317 "Trial Balance Cache Info"
{
    Caption = 'Trial Balance Cache Info';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Primary key field for trial balance cache info table singleton record.
        /// </summary>
        field(1; "Primary Key"; Code[10])
        {
            AllowInCustomizations = Never;
            Caption = 'Primary Key';
        }
        /// <summary>
        /// Timestamp when trial balance cache data was last updated or modified.
        /// </summary>
        field(2; "Last Modified Date/Time"; DateTime)
        {
            Caption = 'Last Modified Date/Time';
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

