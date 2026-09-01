// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol;

using Microsoft.Finance.VAT.Clause;

pageextension 37221 "PEPPOL VAT Clauses" extends "VAT Clauses"
{
    layout
    {
        addlast(group)
        {
            field("VATEX Code"; Rec."VATEX Code")
            {
                ApplicationArea = Basic, Suite;
            }
        }
    }
}
