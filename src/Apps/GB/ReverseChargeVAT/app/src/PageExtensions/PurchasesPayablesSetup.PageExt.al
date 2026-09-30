// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Setup;

using Microsoft.Purchases.Setup;

pageextension 10556 "Purchases & Payables Setup" extends "Purchases & Payables Setup"
{
    layout
    {
        addafter("Background Posting")
        {
            group("Reverse Charge GB")
            {
                Caption = 'Reverse Charge';
                field("Reverse Charge VAT Post. Gr."; Rec."Reverse Charge VAT Post. Gr.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT Business Posting Group code for reverse charge VAT.';
                }
                field("Domestic Vendors GB"; Rec."Domestic Vendors GB")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT Business Posting Group code for domestic UK vendors.';
                }
            }
        }
    }


}