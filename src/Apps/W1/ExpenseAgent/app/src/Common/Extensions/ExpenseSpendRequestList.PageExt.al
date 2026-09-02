#if not CLEAN30
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.SpendRequest;

pageextension 6903 "Expense Spend Request List" extends "Spend Request List"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'The Expense Agent no longer extends the generic Spend Request pages. Travel-specific fields and actions moved to the dedicated Travel Request pages.';
    ObsoleteTag = '30.0';

    layout
    {
        addafter("Requested By")
        {
            field("Requested For"; Rec."Requested For")
            {
                ApplicationArea = Basic, Suite;
                Visible = false;
                ToolTip = 'Specifies the expense user for whom the spend request is being created.';
            }
        }
    }
    actions
    {
        addlast(Navigation)
        {
            action("Travelers")
            {
                Image = Travel;
                Caption = 'Travelers';
                ToolTip = 'View the travelers associated with this spend request.';
                ApplicationArea = Basic, Suite;
                Visible = false;
                RunObject = page "Travelers";
                RunPageLink = "Spend Request No." = field("No.");
            }
        }
        addafter(Dimensions_Promoted)
        {
            actionref(Travelers_Promoted; Travelers)
            {
            }
        }
    }
}
#endif