// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.BankAccount;

/// <summary>
/// Specialized bank account list focused on payment processing and electronic banking.
/// Displays bank accounts suitable for payment export and electronic fund transfers.
/// </summary>
/// <remarks>
/// Source Table: Bank Account (270). Used for payment-specific bank account selection.
/// Optimized for payment processing workflows and electronic banking operations.
/// </remarks>
page 1282 "Payment Bank Account List"
{
    Caption = 'Payment Bank Account List';
    CardPageID = "Payment Bank Account Card";
    Editable = false;
    PageType = List;
    SourceTable = "Bank Account";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the bank where you have the bank account.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the relevant currency code for the bank account.';
                }
                field(Balance; Rec.Balance)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank account''s current balance denominated in the applicable foreign currency.';
                }
                field(Linked; Linked)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Linked';
                    ToolTip = 'Specifies that the bank account is linked to its related online bank account.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        Linked := Rec.IsLinkedToBankStatementServiceProvider();
    end;

    var
        Linked: Boolean;
}

