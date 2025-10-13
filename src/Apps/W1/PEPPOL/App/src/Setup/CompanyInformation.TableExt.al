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
        field(37200; "PEPPOL 3.0 Sales Format"; Enum "PEPPOL 3.0 Format")
        {
            Caption = 'Peppol 3.0 Sales Format';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the PEPPOL 3.0 format to be used for electronic documents of type sales.';
        }
        field(37201; "PEPPOL 3.0 Service Format"; Enum "PEPPOL 3.0 Format")
        {
            Caption = 'Peppol 3.0 Service Format';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the PEPPOL 3.0 format to be used for electronic documents of type service.';
        }
    }
}