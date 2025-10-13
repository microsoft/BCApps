// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol;

using Microsoft.Foundation.Company;

/// <summary>
/// Page extension for Company Information to add PEPPOL e-document format configuration.
/// Extends the Company Information page with controls for selecting electronic document formats.
/// </summary>
pageextension 37200 "Company Information" extends "Company Information"
{
    layout
    {
        addlast(content)
        {
            group("PEPPOL")
            {
                Caption = 'PEPPOL 3.0';

                field("PEPPOL 3.0 Sales Format"; Rec."PEPPOL 3.0 Sales Format")
                {
                    ApplicationArea = All;
                }
                field("PEPPOL 3.0 Service Format"; Rec."PEPPOL 3.0 Service Format")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}