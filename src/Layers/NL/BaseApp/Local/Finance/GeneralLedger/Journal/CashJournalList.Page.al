// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.Bank.Statement;

page 11405 "Cash Journal List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Cash Journal';
    CardPageID = "Cash Journal";
    Editable = false;
    PageType = List;
    SourceTable = "CBG Statement";
    SourceTableView = sorting(Type)
                      where(Type = const(Cash));
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Journal Template Name"; Rec."Journal Template Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the journal template.';
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the statement.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a document number for the CBG statement of type Bank/Giro.';
                }
                field(Date; Rec.Date)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when you created the CBG statement.';
                }
                field(Currency; Rec.Currency)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency code for the amounts on the statement lines.';
                }
                field("Opening Balance"; Rec."Opening Balance")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the current balance (LCY) of the bank/giro or cash account.';
                }
                field("Closing Balance"; Rec."Closing Balance")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the new closing balance, after you have entered all statements in the Bank/Giro journal or all payment/receipt entries.';
                }
            }
        }
    }

    actions
    {
    }
}

