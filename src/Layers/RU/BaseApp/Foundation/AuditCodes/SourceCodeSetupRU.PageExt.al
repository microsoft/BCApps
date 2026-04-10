// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.AuditCodes;

pageextension 12400 SourceCodeSetupRU extends "Source Code Setup"
{
    layout
    {
        addafter("Cash Flow Worksheet")
        {
            field("Bank Payments"; Rec."Bank Payments")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the source code for bank payment orders.';
            }
            field("Bank Reconciliations"; Rec."Bank Reconciliations")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the source code for bank reconciliations.';
            }
            field("Cash Order Payments"; Rec."Cash Order Payments")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the source code for the cash order payments.';
            }
            field("Tax Difference Journal"; Rec."Tax Difference Journal")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the source code for the tax difference journal.';
            }
        }
    }
}