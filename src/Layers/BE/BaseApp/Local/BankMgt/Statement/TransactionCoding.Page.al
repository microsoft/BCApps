#pragma warning disable AA0247
page 2000045 "Transaction Coding"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Transaction Coding';
    PageType = List;
    SourceTable = "Transaction Coding";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Bank Account No."; Rec."Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank account number that this combination is valid for.';
                }
                field("Transaction Family"; Rec."Transaction Family")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the transaction family of the coded transaction.';
                }
                field(Transaction; Rec.Transaction)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the transaction of the coded transaction.';
                }
                field("Transaction Category"; Rec."Transaction Category")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the category of the transaction.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description used when you post this combination.';
                }
                field("Globalisation Code"; Rec."Globalisation Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'This code specifies whether the coded transaction refers to a global or a detailed movement.';
                }
                field("Account Type"; Rec."Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of account that the entry on the journal line will be posted to.';
                }
                field("Account No."; Rec."Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the G/L account, bank, customer, or vendor that the journal line is linked to.';
                }
            }
        }
    }

    actions
    {
    }
}

