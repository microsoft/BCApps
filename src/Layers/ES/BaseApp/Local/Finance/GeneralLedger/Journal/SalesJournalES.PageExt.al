// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

#pragma warning disable AS0088
pageextension 10743 "Sales Journal ES" extends "Sales Journal"
{
    layout
    {
        addafter("Direct Debit Mandate ID")
        {
            field("Correction Type"; Rec."Correction Type")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the type of correction.';
                Visible = false;
            }
            field("Corrected Invoice No."; Rec."Corrected Invoice No.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the number of corrected invoice.';
                Visible = false;
            }
        }
    }
}
