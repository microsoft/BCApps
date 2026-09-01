// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Setup;

pageextension 7000145 "SII VAT Posting Setup Card" extends "VAT Posting Setup Card"
{
    layout
    {
        addafter("Tax Category")
        {
            field("Sales Special Scheme Code"; Rec."Sales Special Scheme Code")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the special scheme codes that are used for VAT reporting for sales. ';
            }
            field("Purch. Special Scheme Code"; Rec."Purch. Special Scheme Code")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the special scheme codes that are used for VAT reporting for purchasing.';
            }
            field("Ignore In SII"; Rec."Ignore In SII")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies if this VAT Posting Setup should be ignored in the SII report.';
            }
        }
    }
}