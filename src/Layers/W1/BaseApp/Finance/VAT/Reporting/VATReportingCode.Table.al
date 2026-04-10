// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

/// <summary>
/// Defines reporting codes used for categorizing and classifying VAT transactions in reports.
/// Provides standardized codes for VAT reporting requirements and transaction classification.
/// </summary>
table 344 "VAT Reporting Code"
{
    Caption = 'VAT Reporting Code';
    LookupPageID = "VAT Reporting Codes";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Unique code identifier for the VAT reporting classification.
        /// </summary>
        field(1; Code; Code[20])
        {
            ToolTip = 'Specifies the VAT reporting code.';
        }
        /// <summary>
        /// Description of the VAT reporting code purpose and usage.
        /// </summary>
        field(2; Description; Text[250])
        {
            ToolTip = 'Specifies the description of the VAT reporting code.';
        }
    }

    keys
    {
        key(Key1; Code)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; Code, Description)
        {
        }
    }
}
