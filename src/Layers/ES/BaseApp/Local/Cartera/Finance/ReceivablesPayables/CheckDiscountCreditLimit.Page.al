// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Check;
using Microsoft.Bank.Ledger;
using Microsoft.Bank.Statement;
using Microsoft.Foundation.Comment;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;

page 7000037 "Check Discount Credit Limit"
{
    Caption = 'Check Discount Credit Limit';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    InstructionalText = 'The credit limit for discount with this bank will be exceeded. Do you still want to proceed?';
    ModifyAllowed = false;
    PageType = ConfirmationDialog;
    SourceTable = "Bank Account";

    layout
    {
        area(content)
        {
            group(Details)
            {
                Caption = 'Details';
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                }
                field("Posted Receiv. Bills Rmg. Amt."; Rec."Posted Receiv. Bills Rmg. Amt.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Discounted so far';
                    ToolTip = 'Specifies the amount pending from the receivables registered at this bank.';
                }
                field(CurrBillGrAmount; CurrBillGrAmount)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Amount of this Bill Group';
                    ToolTip = 'Specifies the amount of the current bill group.';
                }
                field(AmountSelected; AmountSelected)
                {
                    ApplicationArea = All;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Amount Selected';
                    ToolTip = 'Specifies the amount selected for the discount.';
                    Visible = AmountSelectedVisible;
                }
                field(TotalAmount; TotalAmount)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Total Amount';
                    ToolTip = 'Specifies the total amount of the receivables registered at this bank.';
                }
                field("Credit Limit for Discount"; Rec."Credit Limit for Discount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the credit limit for the discount of bills available at this particular bank.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Bank Acc.")
            {
                Caption = '&Bank Acc.';
                Image = Bank;
                action("Ledger E&ntries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ledger E&ntries';
                    RunObject = Page "Bank Account Ledger Entries";
                    RunPageLink = "Bank Account No." = field("No.");
                    RunPageView = sorting("Bank Account No.", "Posting Date");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'Shows the ledger entries for this bank account.';
                }
                action("Co&mments")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Comment Sheet";
                    RunPageLink = "Table Name" = const("Bank Account"),
                                  "No." = field("No.");
                    ToolTip = 'Shows the comments for this bank account.';
                }
                action(Statistics)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Statistics';
                    Image = Statistics;
                    RunObject = Page "Bank Account Statistics";
                    RunPageLink = "No." = field("No."),
                                  "Date Filter" = field("Date Filter"),
                                  "Global Dimension 1 Filter" = field("Global Dimension 1 Filter"),
                                  "Global Dimension 2 Filter" = field("Global Dimension 2 Filter");
                    ShortCutKey = 'F7';
                    ToolTip = 'Specifies the statistics for this bank account.';
                }
                action(Balance)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Balance';
                    Image = Balance;
                    RunObject = Page "Bank Account Balance";
                    RunPageLink = "No." = field("No."),
                                  "Global Dimension 1 Filter" = field("Global Dimension 1 Filter"),
                                  "Global Dimension 2 Filter" = field("Global Dimension 2 Filter");
                    ToolTip = 'Specifies the balance for this bank account.';
                }
                action("St&atements")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'St&atements';
                    RunObject = Page "Bank Account Statement List";
                    RunPageLink = "Bank Account No." = field("No.");
                    ToolTip = 'Specifies the statements for this bank account.';
                }
                action("Chec&k Ledger Entries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Chec&k Ledger Entries';
                    Image = CheckLedger;
                    RunObject = Page "Check Ledger Entries";
                    RunPageLink = "Bank Account No." = field("No.");
                    RunPageView = sorting("Bank Account No.", "Entry Status", "Check No.");
                    ToolTip = 'Specifies the ledger entries for this bank account.';
                }
                separator(Action41)
                {
                }
                action("&Operation Fees")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Operation Fees';
                    RunObject = Page "Operation Fees";
                    RunPageLink = Code = field("Operation Fees Code"),
                                  "Currency Code" = field("Currency Code");
                    ToolTip = 'Specifies the operation fees for this bank account.';
                }
                action("Customer Ratings")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Customer Ratings';
                    Image = CustomerRating;
                    RunObject = Page "Customer Ratings";
                    RunPageLink = Code = field("Customer Ratings Code"),
                                  "Currency Code" = field("Currency Code");
                    ToolTip = 'Specifies the customer ratings for this bank account.';
                }
                separator(Action5)
                {
                    Caption = '';
                }
                action("Bill &Groups")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bill &Groups';
                    Image = VoucherGroup;
                    RunObject = Page "Bill Groups List";
                    RunPageLink = "Bank Account No." = field("No.");
                    RunPageView = sorting("Bank Account No.");
                    ToolTip = 'Specifies the bill groups for this bank account.';
                }
                action("Posted Bill Groups")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posted Bill Groups';
                    Image = PostedVoucherGroup;
                    RunObject = Page "Posted Bill Groups List";
                    RunPageLink = "Bank Account No." = field("No.");
                    RunPageView = sorting("Bank Account No.");
                    ToolTip = 'Specifies the posted bill groups for this bank account.';
                }
                separator(Action7)
                {
                    Caption = '';
                }
                action("Payment O&rders")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Payment O&rders';
                    RunObject = Page "Payment Orders List";
                    RunPageLink = "Bank Account No." = field("No.");
                    RunPageView = sorting("Bank Account No.");
                    ToolTip = 'Specifies the payment orders for this bank account.';
                }
                action("Posted P&ayment Orders")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posted P&ayment Orders';
                    Image = PostedPayment;
                    RunObject = Page "Posted Payment Orders List";
                    RunPageLink = "Bank Account No." = field("No.");
                    RunPageView = sorting("Bank Account No.");
                    ToolTip = 'Specifies the posted payment orders for this bank account.';
                }
                separator(Action50)
                {
                }
                action("Posted Recei&vable Bills")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posted Recei&vable Bills';
                    Image = PostedReceivableVoucher;
                    RunObject = Page "Bank Cat. Posted Receiv. Bills";
                    ToolTip = 'Specifies the posted receivable bills for this bank account.';
                }
                action("Posted Pa&yable Bills")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posted Pa&yable Bills';
                    Image = PostedPayableVoucher;
                    RunObject = Page "Bank Cat. Posted Payable Bills";
                    ToolTip = 'Specifies the posted payable bills for this bank account.';
                }
            }
        }
    }

    trigger OnInit()
    begin
        AmountSelectedVisible := true;
    end;

    trigger OnOpenPage()
    begin
        OnActivateForm();
    end;

    var
        CurrBillGrAmount: Decimal;
        AmountSelected: Decimal;
        TotalAmount: Decimal;
        AmountSelectedVisible: Boolean;

    [Scope('OnPrem')]
    procedure SetValues(CurrAmount: Decimal; SelAmount: Decimal)
    begin
        CurrBillGrAmount := CurrAmount;
        AmountSelected := SelAmount;
    end;

    local procedure OnActivateForm()
    begin
        Rec.SetRange("Dealing Type Filter", Rec."Dealing Type Filter"::Discount);
        Rec.SetRange("Status Filter", Rec."Status Filter"::Open);
        Rec.CalcFields("Posted Receiv. Bills Amt.");
        TotalAmount := Rec."Posted Receiv. Bills Rmg. Amt." + CurrBillGrAmount + AmountSelected;
        AmountSelectedVisible := AmountSelected <> 0;
    end;
}

