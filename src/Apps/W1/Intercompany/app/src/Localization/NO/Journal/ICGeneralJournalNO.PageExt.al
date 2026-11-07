#if INTERCOMPANY_NO
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Journal;

pageextension 8558 "IC General Journal NO" extends "IC General Journal"
{
    layout
    {
        addbefore("Job Queue Status")
        {
            field("Payment Type Code Abroad"; Rec."Payment Type Code Abroad")
            {
                ApplicationArea = Intercompany;
                ToolTip = 'Specifies a two-digit code for the payment type.';
                Visible = false;
            }
            field("Specification (Norges Bank)"; Rec."Specification (Norges Bank)")
            {
                ApplicationArea = Intercompany;
                ToolTip = 'Specifies information for your local government bank.';
                Visible = false;
            }
        }
    }
}
#endif
