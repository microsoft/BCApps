// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseTaxIntegration;

using Microsoft.Finance.GeneralLedger.Journal;

pageextension 7058 "WHT General Journal" extends "General Journal"
{
    layout
    {
        addafter("Bal. Gen. Prod. Posting Group")
        {
            field("Expense Category"; Rec."Expense Category")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the expense category for the journal line.';
            }
        }
    }
}
