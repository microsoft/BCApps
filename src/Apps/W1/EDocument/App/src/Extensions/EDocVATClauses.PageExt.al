// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

using Microsoft.Finance.VAT.Clause;

pageextension 6173 "E-Doc. VAT Clauses" extends "VAT Clauses"
{
    layout
    {
        addafter(Code)
        {
            field("VATEX Code"; Rec."VATEX Code")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the VATEX exemption reason code (BT-121) from the CEF VATEX code list, e.g. VATEX-EU-AE, VATEX-EU-G, VATEX-EU-IC.';
            }
        }
    }
}
