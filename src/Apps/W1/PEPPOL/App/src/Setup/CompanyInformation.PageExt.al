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
            /// <summary>
            /// Group for e-document configuration settings.
            /// </summary>
            group("E-Documents")
            {
                Caption = 'E-Documents';

                /// <summary>
                /// Field for selecting the e-document format to be used for PEPPOL exports.
                /// </summary>
                field("E-Document Format"; Rec."E-Document Format")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}