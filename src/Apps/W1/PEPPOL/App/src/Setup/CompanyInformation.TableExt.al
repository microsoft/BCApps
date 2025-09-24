// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol;

using Microsoft.Foundation.Company;

/// <summary>
/// Table extension for Company Information to add PEPPOL e-document format selection.
/// Extends the Company Information table with fields for configuring electronic document formats.
/// </summary>
tableextension 37200 "Company Information" extends "Company Information"
{
    fields
    {
        /// <summary>
        /// Specifies the e-document format to be used for electronic documents.
        /// This field determines which PEPPOL format provider implementation to use.
        /// </summary>
        field(37200; "E-Document Format"; Enum "E-Document Format")
        {
            Caption = 'E-Document Format';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the e-document format to be used for electronic documents.';
        }
    }
}