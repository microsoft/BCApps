// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Finance.VAT.Setup;

pageextension 7000137 "SII VAT Posting Setup" extends "VAT Posting Setup"
{
    layout
    {
        addafter("Tax Category")
        {
            field("Sales Special Scheme Code"; Rec."Sales Special Scheme Code")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the special scheme codes that are used for VAT reporting for sales.';
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
            field("One Stop Shop Reporting"; Rec."One Stop Shop Reporting")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies if this VAT Posting Setup is aligned with the One Stop Shop system. If this option is enabled then the VAT posting has no changes, but is reported under the ImporteTAIReglasLocalizacion xml node for the SII reporting. This is only applied to sales.';
            }
        }
    }
}