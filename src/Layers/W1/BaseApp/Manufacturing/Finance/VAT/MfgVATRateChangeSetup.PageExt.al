// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.RateChange;

pageextension 99000794 "Mfg. VAT Rate Change Setup" extends "VAT Rate Change Setup"
{
    layout
    {
        addafter("Update Gen. Prod. Post. Groups")
        {
            field("Update Work Centers"; Rec."Update Work Centers")
            {
                ApplicationArea = Manufacturing;
                ToolTip = 'Specifies the VAT rate change for work centers.';
            }
            field("Update Machine Centers"; Rec."Update Machine Centers")
            {
                ApplicationArea = Manufacturing;
                ToolTip = 'Specifies the VAT rate change for machine centers.';
            }
        }
        addafter("Ignore Status on Purch. Docs.")
        {
            field("Update Production Orders"; Rec."Update Production Orders")
            {
                ApplicationArea = Manufacturing;
                ToolTip = 'Specifies the VAT rate change for production orders.';
            }
        }
    }

}