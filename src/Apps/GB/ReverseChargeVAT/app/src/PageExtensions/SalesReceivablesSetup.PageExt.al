// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Setup;

using Microsoft.Sales.Setup;

pageextension 10557 "Sales & Receivables Setup" extends "Sales & Receivables Setup"
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
                field("Domestic Customers GB"; Rec."Domestic Customers GB")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT Business Posting Group code for domestic UK customers.';
                }
                field("Invoice Wording GB"; Rec."Invoice Wording GB")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the text that is printed on the invoice indicating that the invoice is a reverse charge transaction.';
                }
            }
        }
    }


}