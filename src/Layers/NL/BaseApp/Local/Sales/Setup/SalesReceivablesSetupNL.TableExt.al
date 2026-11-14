// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Setup;

/// <summary>
/// Extends the Sales and Receivables Setup table with NL-specific configuration fields.
/// </summary>
tableextension 11469 "Sales Receivables Setup NL" extends "Sales & Receivables Setup"
{
    fields
    {
        /// <summary>
        /// Specifies whether orders are enabled in the NL sales workflow.
        /// </summary>
        field(11316; Orders; Boolean)
        {
            Caption = 'Orders';
            DataClassification = CustomerContent;
        }
    }
}
