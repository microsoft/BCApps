// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

/// <summary>
/// Defines company size categories for financial analysis and reporting classification.
/// Used to categorize companies for comparative analysis and benchmarking purposes.
/// </summary>
table 532 "Company Size"
{
    LookupPageId = "Company Sizes";
    DrillDownPageId = "Company Sizes";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Unique code identifying the company size category.
        /// </summary>
        field(1; Code; Code[20]) { }
        /// <summary>
        /// Descriptive name for the company size category.
        /// </summary>
        field(2; Description; Text[100]) { }
    }

    keys
    {
        key(Key1; Code)
        {
            Clustered = true;
        }
    }
}
