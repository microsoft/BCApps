// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.WithholdingTax;

using Microsoft.Finance.GeneralLedger.Journal;

pageextension 6800 "Withholding Payment Journal" extends "Payment Journal"
{
    layout
    {
        addafter("VAT Prod. Posting Group")
        {
            field("Withholding Tax Bus. Post. Group"; Rec."Wthldg. Tax Bus. Post. Group")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the Withholding Tax Business Posting Group for the Payment Journal.';
                Visible = false;
            }
            field("Withholding Tax Prod. Post. Group"; Rec."Wthldg. Tax Prod. Post. Group")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the Withholding Tax Product Posting Group for the Payment Journal.';
                Visible = false;
            }
        }
    }
}