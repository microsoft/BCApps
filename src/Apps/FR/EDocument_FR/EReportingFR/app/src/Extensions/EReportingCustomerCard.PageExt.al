// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.Sales.Customer;

pageextension 10972 "E-Reporting Customer Card" extends "Customer Card"
{
    layout
    {
        addafter("VAT Registration No.")
        {
            field("FR E-Reporting Trans. Type"; Rec."FR E-Reporting Trans. Type")
            {
                ApplicationArea = Basic, Suite;
            }
            field("FR Electronic Address"; Rec."FR Electronic Address")
            {
                ApplicationArea = Basic, Suite;
            }
#if not CLEAN29
#pragma warning disable AS0105
            field("FR Elec. Address Scheme"; Rec."FR Elec. Address Scheme")
            {
                ApplicationArea = Basic, Suite;
                ObsoleteReason = 'French buyer electronic addresses always use scheme 0225.';
                ObsoleteState = Pending;
                ObsoleteTag = '29.0';
                Visible = false;
            }
#pragma warning restore AS0105
#endif
        }
    }
}
