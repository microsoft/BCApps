// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Finance.VAT.Clause;

pageextension 7000136 "SII VAT Clauses" extends "VAT Clauses"
{
    layout
    {
        addafter("Description 2")
        {
            field("SII Exemption Code"; Rec."SII Exemption Code")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the SII Exemption of the VAT clause.';
            }
        }
    }
}
