// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Peppol.DE;

using Microsoft.Foundation.Company;

pageextension 37400 "PEPPOL Company Information DE" extends "Company Information"
{
    layout
    {
        addafter("Use GLN in Electronic Document")
        {
            field("Use Reg. No. in E-Document"; Rec."Use Reg. No. in E-Document")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies whether the company registration number is used to identify the company in electronic documents when the GLN and VAT registration number are blank.';
            }
        }
    }
}