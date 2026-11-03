// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7452 "EA Card Liability Transfer"
{
    Caption = 'Transfer Card Liability';
    PageType = StandardDialog;

    layout
    {
        area(Content)
        {
            group(Transfer)
            {
                InstructionalText = 'Transfer the existing card-payable liability to the provider corporate-card bank account. Expense and VAT amounts will not be posted again.';
                field("Posting Date"; PostingDate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posting Date';
                    ToolTip = 'Specifies the posting date of the liability transfer.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        PostingDate := WorkDate();
    end;

    internal procedure GetPostingDate(): Date
    begin
        exit(PostingDate);
    end;

    var
        PostingDate: Date;
}
