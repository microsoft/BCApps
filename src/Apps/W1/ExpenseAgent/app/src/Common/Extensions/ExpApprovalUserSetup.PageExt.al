#if not CLEAN30
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using System.Automation;

pageextension 6977 "Exp. Approval User Setup" extends "Approval User Setup"
{
    layout
    {
        addafter("Unlimited Purchase Approval")
        {
            field("Expense Amount Approval Limit"; Rec."Expense Amount Approval Limit")
            {
                ApplicationArea = Suite;
                ToolTip = 'Specifies the maximum amount in local currency this user can approve for the record.';
                ObsoleteState = Pending;
                ObsoleteReason = 'Replaced by the Approval Limit field on Expense User.';
                ObsoleteTag = '30.0';
            }
            field("Unlimited Expense Approval"; Rec."Unlimited Expense Approval")
            {
                ApplicationArea = Suite;
                ToolTip = 'Specifies that the user can approve expense records without a maximum amount. When selected, leave the Expense Amount Approval Limit field empty.';
                ObsoleteState = Pending;
                ObsoleteReason = 'Replaced by the approval settings on Expense User.';
                ObsoleteTag = '30.0';
            }
        }
    }
}
#endif