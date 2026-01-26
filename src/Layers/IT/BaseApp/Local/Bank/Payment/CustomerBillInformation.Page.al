// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Account;

page 35480 "Customer Bill Information"
{
    Caption = 'Customer Bill Information';
    PageType = CardPart;
    SourceTable = "Customer Bill Header";

    layout
    {
        area(content)
        {
            field(TotalPayments; TotalPayments)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Total Payments';
                Editable = false;
                ToolTip = 'Specifies the total payments.';
            }
            field(Balance; Balance)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Bank Balance';
                Editable = false;
                ToolTip = 'Specifies the bank balance.';
            }
            field(NewBalance; NewBalance)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'New Bank Balance';
                Editable = false;
                ToolTip = 'Specifies if this is a new bank balance.';
            }
            field(CreditLimit; CreditLimit)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Bank Credit Limit';
                Editable = false;
                ToolTip = 'Specifies the bank credit limit.';
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        CalcBalance();
    end;

    trigger OnOpenPage()
    begin
        CalcBalance();
    end;

    var
        Balance: Decimal;
        TotalPayments: Decimal;
        NewBalance: Decimal;
        CreditLimit: Decimal;

    [Scope('OnPrem')]
    procedure CalcBalance()
    var
        BankAcc: Record "Bank Account";
        BankAccPostingGroup: Record "Bank Account Posting Group";
        BillPostingGroup: Record "Bill Posting Group";
        GLAcc: Record "G/L Account";
    begin
        if Rec."Bank Account No." <> '' then begin
            BankAcc.Get(Rec."Bank Account No.");
            if Rec.Type <> Rec.Type::" " then begin
                BankAcc.TestField("Bank Acc. Posting Group");
                BankAccPostingGroup.Get(BankAcc."Bank Acc. Posting Group");
                BillPostingGroup.Get(Rec."Bank Account No.", Rec."Payment Method Code");
                case Rec.Type of
                    Rec.Type::"Bills For Collection":
                        begin
                            if BillPostingGroup."Bills For Collection Acc. No." <> '' then
                                GLAcc.Get(BillPostingGroup."Bills For Collection Acc. No.");

                            GLAcc.CalcFields(Balance);
                            Balance := GLAcc.Balance;
                        end;
                    Rec.Type::"Bills For Discount":
                        begin
                            if BillPostingGroup."Bills For Discount Acc. No." <> '' then
                                GLAcc.Get(BillPostingGroup."Bills For Discount Acc. No.");

                            GLAcc.CalcFields(Balance);
                            Balance := GLAcc.Balance;
                        end;
                    Rec.Type::"Bills Subject To Collection":
                        begin
                            if BillPostingGroup."Bills Subj. to Coll. Acc. No." <> '' then
                                GLAcc.Get(BillPostingGroup."Bills Subj. to Coll. Acc. No.");

                            GLAcc.CalcFields(Balance);
                            Balance := GLAcc.Balance;
                        end;
                end;
            end;
            Rec.CalcFields("Total Amount");
            TotalPayments := Rec."Total Amount";
            NewBalance := Balance + TotalPayments;
            CreditLimit := -BankAcc."Credit Limit";
        end else begin
            TotalPayments := 0;
            Balance := 0;
            NewBalance := 0;
            CreditLimit := 0;
        end;
    end;
}

