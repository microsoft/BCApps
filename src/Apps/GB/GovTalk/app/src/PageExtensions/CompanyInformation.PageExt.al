// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.GovTalk;

using Microsoft.Foundation.Company;

pageextension 10526 "Company Information" extends "Company Information"
{
    layout
    {
        addafter(Shipping)
        {
            group(Statutory_)
            {
                Caption = 'Statutory';
                field("Branch Number GB"; Rec."Branch Number GB")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the three-digit numeric branch number.';
                }
            }
        }
    }

}